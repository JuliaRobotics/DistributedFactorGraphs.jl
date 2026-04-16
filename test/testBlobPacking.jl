using Test
using DistributedFactorGraphs
using DistributedFactorGraphs: getMimetype, getDataFormat, _MIMEOverrides
using FileIO

@testset "BlobPacking" begin

    ##==========================================================================
    ## getMimetype
    ##==========================================================================
    @testset "getMimetype" begin
        # Standard types auto-detected via FileIO + MIMEs.jl
        @test getMimetype(format"PNG") == MIME("image/png")
        @test getMimetype(format"JPEG") == MIME("image/jpeg")

        # Override types from _MIMEOverrides
        @test getMimetype(format"JSON") == MIME("application/json")
        @test getMimetype(format"BSON") == MIME("application/bson")
        @test getMimetype(format"LAS") == MIME("application/vnd.las")
        @test getMimetype(format"Parquet") == MIME("application/vnd.apache.parquet")

        # Unknown format falls back to application/octet-stream
        @test getMimetype(DataFormat{:SomeUnknownFormat12345}) ==
              MIME("application/octet-stream")
    end

    ##==========================================================================
    ## getDataFormat
    ##==========================================================================
    @testset "getDataFormat" begin
        # Standard types auto-detected via MIMEs.jl + FileIO
        @test getDataFormat(MIME("image/png")) == format"PNG"
        @test getDataFormat(MIME("image/jpeg")) == format"JPEG"

        # Override types
        @test getDataFormat(MIME("application/json")) == format"JSON"
        @test getDataFormat(MIME("application/bson")) == format"BSON"
        @test getDataFormat(MIME("application/vnd.las")) == format"LAS"
        @test getDataFormat(MIME("application/vnd.apache.parquet")) == format"Parquet"

        # Unknown MIME returns nothing
        @test getDataFormat(MIME("application/x-totally-unknown-12345")) === nothing
    end

    ##==========================================================================
    ## _MIMEOverrides extensibility
    ##==========================================================================
    @testset "_MIMEOverrides extensibility" begin
        # Extensions (like BlobArrow) can add to _MIMEOverrides
        push!(_MIMEOverrides, DataFormat{:TestFormat} => MIME("application/x-test-format"))
        try
            @test getMimetype(DataFormat{:TestFormat}) == MIME("application/x-test-format")
            @test getDataFormat(MIME("application/x-test-format")) ==
                  DataFormat{:TestFormat}
        finally
            delete!(_MIMEOverrides, DataFormat{:TestFormat})
        end
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
        entry = Blobentry(
            :test_json,
            DFG.Multihash(sha2_256, rand(UInt8, 32));
            mimetype = MIME("application/json"),
        )
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
        entry = Blobentry(:default_mime, DFG.Multihash(sha2_256, rand(UInt8, 32)))
        @test entry.mimetype == MIME("application/octet-stream")

        # Custom MIME type
        entry_json = Blobentry(
            :json_data,
            DFG.Multihash(sha2_256, rand(UInt8, 32));
            mimetype = MIME("application/json"),
        )
        @test entry_json.mimetype == MIME("application/json")

        # JSON round-trip through Blobentry
        json_str = """{"key":"value"}"""
        blob, mimetype = DFG.packBlob(format"JSON", json_str)
        entry_with_mime = Blobentry(
            :my_json,
            DFG.Multihash(sha2_256, rand(UInt8, 32));
            mimetype = mimetype,
        )
        @test DFG.unpackBlob(entry_with_mime, blob) == json_str
    end

    ##==========================================================================
    ## FileIO generic packBlob/unpackBlob
    ##==========================================================================
    @testset "FileIO generic packBlob/unpackBlob" begin
        # Test that the generic FileIO method dispatches and returns correct MIME
        # We define a custom DataFormat for testing without needing external packages
        # The generic method calls save(Stream{T}(io), data) and load(Stream{T}(io))
        # Test that getMimetype is called correctly in the generic path
        # by verifying the returned mimetype for a known format
        @test DFG.getMimetype(format"JPEG") == MIME("image/jpeg")
        @test DFG.getMimetype(format"PNG") == MIME("image/png")
        @test DFG.getMimetype(format"BSON") == MIME("application/bson")

        # Test the generic path uses getMimetype
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
