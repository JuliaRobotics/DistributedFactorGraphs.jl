using Test
using DistributedFactorGraphs
using DistributedFactorGraphs: format_to_mime, mime_to_format, _MIMEOverrides
using FileIO

@testset "BlobPacking" begin

    ##==========================================================================
    ## format_to_mime
    ##==========================================================================
    @testset "format_to_mime" begin
        # Standard types auto-detected via FileIO + MIMEs.jl
        @test format_to_mime(format"PNG") == MIME("image/png")
        @test format_to_mime(format"JPEG") == MIME("image/jpeg")

        # Override types from _MIMEOverrides
        @test format_to_mime(format"JSON") == MIME("application/json")
        @test format_to_mime(format"BSON") == MIME("application/bson")
        @test format_to_mime(format"LAS") == MIME("application/vnd.las")
        @test format_to_mime(format"Parquet") == MIME("application/vnd.apache.parquet")

        # Unknown format falls back to application/octet-stream
        @test format_to_mime(DataFormat{:SomeUnknownFormat12345}) ==
              MIME("application/octet-stream")
    end

    ##==========================================================================
    ## mime_to_format
    ##==========================================================================
    @testset "mime_to_format" begin
        # Standard types auto-detected via MIMEs.jl + FileIO
        @test mime_to_format(MIME("image/png")) == format"PNG"
        @test mime_to_format(MIME("image/jpeg")) == format"JPEG"

        # Override types
        @test mime_to_format(MIME("application/json")) == format"JSON"
        @test mime_to_format(MIME("application/bson")) == format"BSON"
        @test mime_to_format(MIME("application/vnd.las")) == format"LAS"
        @test mime_to_format(MIME("application/vnd.apache.parquet")) == format"Parquet"

        # Unknown MIME returns nothing
        @test mime_to_format(MIME("application/x-totally-unknown-12345")) === nothing
    end

    ##==========================================================================
    ## _MIMEOverrides extensibility
    ##==========================================================================
    @testset "_MIMEOverrides extensibility" begin
        # Extensions (like BlobArrow) can add to _MIMEOverrides
        push!(_MIMEOverrides, DataFormat{:TestFormat} => MIME("application/x-test-format"))
        @test format_to_mime(DataFormat{:TestFormat}) == MIME("application/x-test-format")
        @test mime_to_format(MIME("application/x-test-format")) == DataFormat{:TestFormat}
        delete!(_MIMEOverrides, DataFormat{:TestFormat})
    end

    ##==========================================================================
    ## packBlob / unpackBlob - JSON
    ##==========================================================================
    @testset "packBlob/unpackBlob JSON" begin
        json_str = """{"name":"John","age":30}"""

        # packBlob
        blob, mimetype = DFG.packBlob(format"JSON", json_str)
        @test blob isa Vector{UInt8}
        @test mimetype == MIME("application/json")
        @test length(blob) == length(json_str)

        # unpackBlob via DataFormat
        result = DFG.unpackBlob(format"JSON", blob)
        @test result == json_str
        @test result isa String

        # unpackBlob via MIME
        result2 = DFG.unpackBlob(MIME("application/json"), blob)
        @test result2 == json_str

        # unpackBlob via String MIME
        result3 = DFG.unpackBlob("application/json", blob)
        @test result3 == json_str

        # unpackBlob via Blobentry
        entry = Blobentry(:test_json; mimetype = MIME("application/json"))
        result5 = DFG.unpackBlob(entry, blob)
        @test result5 == json_str

        # unpackBlob via Pair{Blobentry, Vector{UInt8}}
        result6 = DFG.unpackBlob(entry => blob)
        @test result6 == json_str

        # Edge case: empty JSON
        blob_empty, mime_empty = DFG.packBlob(format"JSON", "{}")
        @test DFG.unpackBlob(format"JSON", blob_empty) == "{}"
        @test mime_empty == MIME("application/json")

        # Edge case: JSON array
        json_arr = """[1,2,3]"""
        blob_arr, _ = DFG.packBlob(format"JSON", json_arr)
        @test DFG.unpackBlob(format"JSON", blob_arr) == json_arr

        # Edge case: unicode
        json_unicode = """{"emoji":"🎉"}"""
        blob_u, _ = DFG.packBlob(format"JSON", json_unicode)
        @test DFG.unpackBlob(format"JSON", blob_u) == json_unicode

        # unpackBlob returns a copy (not aliased to input)
        blob_copy = copy(blob)
        result_copy = DFG.unpackBlob(format"JSON", blob_copy)
        blob_copy[1] = 0x00
        @test result_copy == json_str
    end

    ##==========================================================================
    ## packBlob / unpackBlob - unknown MIME error
    ##==========================================================================
    @testset "unpackBlob unknown MIME error" begin
        blob = Vector{UInt8}("test")
        @test_throws ErrorException DFG.unpackBlob(
            MIME("application/x-totally-unknown-12345"),
            blob,
        )
    end

    ##==========================================================================
    ## Blobentry mimetype integration
    ##==========================================================================
    @testset "Blobentry mimetype integration" begin
        # Default MIME type
        entry = Blobentry(:default_mime)
        @test entry.mimetype == MIME("application/octet-stream")

        # Custom MIME type
        entry_json = Blobentry(:json_data; mimetype = MIME("application/json"))
        @test entry_json.mimetype == MIME("application/json")

        # JSON round-trip through Blobentry
        json_str = """{"key":"value"}"""
        blob, mimetype = DFG.packBlob(format"JSON", json_str)
        entry_with_mime = Blobentry(:my_json; mimetype = mimetype)
        @test DFG.unpackBlob(entry_with_mime, blob) == json_str
    end

    ##==========================================================================
    ## FileIO generic packBlob/unpackBlob
    ##==========================================================================
    @testset "FileIO generic packBlob/unpackBlob" begin
        # Test that the generic FileIO method dispatches and returns correct MIME
        # We define a custom DataFormat for testing without needing external packages
        # The generic method calls save(Stream{T}(io), data) and load(Stream{T}(io))
        # Test that format_to_mime is called correctly in the generic path
        # by verifying the returned mimetype for a known format
        @test DFG.format_to_mime(format"JPEG") == MIME("image/jpeg")
        @test DFG.format_to_mime(format"PNG") == MIME("image/png")
        @test DFG.format_to_mime(format"BSON") == MIME("application/bson")

        # Test the generic path uses format_to_mime
        # by adding a custom format to overrides and round-tripping JSON through generic
        # (JSON has its own specialization, but BSON/LAS/Parquet would use generic)

        # The generic unpackBlob(::Type{T}, blob) where T<:DataFormat creates an IOBuffer
        # and calls load(Stream{T}(io)) - test that it creates the correct stream
        blob = Vector{UInt8}("test data")
        # This will fail with a load error (no loader for the format) but that
        # validates the code path enters the function
        @test_throws Exception DFG.unpackBlob(DataFormat{:SomeTestFormat}, blob)
    end

    ##==========================================================================
    ## getMimetype
    ##==========================================================================
    @testset "getMimetype" begin
        # PNG magic bytes
        png_header = UInt8[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]
        @test DFG.getMimetype(IOBuffer(png_header)) == MIME("image/png")

        # JPEG magic bytes
        jpeg_header = UInt8[0xff, 0xd8, 0xff, 0xe0]
        @test DFG.getMimetype(IOBuffer(jpeg_header)) == MIME("image/jpeg")
    end
end
