using Test
using UUIDs
using DistributedFactorGraphs: Tables

testDFGAPI = GraphsDFG

##==============================================================================
## LinkStore
##==============================================================================
@testset "LinkStore" begin
    tmpdir = mktempdir()
    try
        csvfile = joinpath(tmpdir, "linkstore_test_$(uuid4()).csv")

        # Create new LinkStore (file does not exist)
        ls = DFG.LinkStore(:links, csvfile)
        @test ls.label == :links
        @test ls.csvfile == csvfile
        @test isempty(ls.cache)
        @test isfile(csvfile)

        # Write a temporary data file to link to
        datafile = joinpath(tmpdir, "linkstore_data_$(uuid4()).bin")
        test_data = rand(UInt8, 100)
        write(datafile, test_data)

        # addBlob! with a link
        blobid = uuid4()
        @test addBlob!(ls, blobid, datafile) == blobid
        @test haskey(ls.cache, blobid)

        # addBlob! duplicate throws
        @test_throws DFG.IdExistsError addBlob!(ls, blobid, datafile)

        # getBlob reads through the link
        retrieved = getBlob(ls, blobid)
        @test retrieved == test_data

        # getBlob for missing id throws
        @test_throws DFG.IdNotFoundError getBlob(ls, uuid4())

        # deleteBlob! is not supported
        @test_throws ErrorException deleteBlob!(ls)
        @test_throws ErrorException deleteBlob!(ls, uuid4())
        @test_throws ErrorException deleteBlob!(ls, Blobentry(:test))

        # Re-open existing CSV to test loading from file
        ls2 = DFG.LinkStore(:links, csvfile)
        @test haskey(ls2.cache, blobid)
        @test ls2.cache[blobid] == datafile
        @test getBlob(ls2, blobid) == test_data

        # Multiple entries
        datafile2 = joinpath(tmpdir, "linkstore_data2_$(uuid4()).bin")
        test_data2 = rand(UInt8, 50)
        write(datafile2, test_data2)
        blobid2 = uuid4()
        addBlob!(ls, blobid2, datafile2)

        # Re-open and verify both entries are loaded
        ls3 = DFG.LinkStore(:links, csvfile)
        @test length(ls3.cache) == 2
        @test getBlob(ls3, blobid) == test_data
        @test getBlob(ls3, blobid2) == test_data2
    finally
        rm(tmpdir; force = true, recursive = true)
    end
end

##==============================================================================
## RowBlobstore
##==============================================================================
@testset "RowBlobstore" begin
    NT = @NamedTuple{a::Vector{Int}, b::Vector{Int}}

    @testset "Construction" begin
        store = DFG.RowBlobstore(:test_rows, NT)
        @test store.label == :test_rows
        @test isempty(store.blobs)
        @test store isa DFG.RowBlobstore{NT}
    end

    @testset "CRUD operations" begin
        store = DFG.RowBlobstore(:test_rows, NT)

        # addBlob!
        id1 = uuid4()
        blob1 = (a = [1, 2], b = [3, 4])
        @test addBlob!(store, id1, blob1) == id1

        id2 = uuid4()
        blob2 = (a = [5, 6], b = [7, 8])
        addBlob!(store, id2, blob2)

        # addBlob! duplicate throws
        @test_throws DFG.IdExistsError addBlob!(store, id1, blob1)

        # getBlob
        @test getBlob(store, id1) == blob1
        @test getBlob(store, id2) == blob2
        @test_throws DFG.IdNotFoundError getBlob(store, uuid4())

        # hasBlob
        @test hasBlob(store, id1)
        @test !hasBlob(store, uuid4())

        # listBlobs
        ids = listBlobs(store)
        @test length(ids) == 2
        @test id1 in ids
        @test id2 in ids

        # deleteBlob!
        @test deleteBlob!(store, id1) == 1
        @test !hasBlob(store, id1)
        @test length(listBlobs(store)) == 1
        @test deleteBlob!(store, uuid4()) == 0
    end

    @testset "RowBlob Tables interface" begin
        rb = DFG.RowBlob(uuid4(), (a = [1, 2], b = [3, 4]))
        @test Tables.columnnames(rb) == (:id, :a, :b)
        @test Tables.getcolumn(rb, 1) isa UUID
        @test Tables.getcolumn(rb, 2) == [1, 2]
        @test Tables.getcolumn(rb, :id) isa UUID
        @test Tables.getcolumn(rb, :a) == [1, 2]
        @test Tables.getcolumn(rb, :b) == [3, 4]
    end

    @testset "Tables integration" begin
        store = DFG.RowBlobstore(:test_rows, NT)
        addBlob!(store, uuid4(), (a = [1, 2], b = [3, 4]))
        addBlob!(store, uuid4(), (a = [5, 6], b = [7, 8]))
        addBlob!(store, uuid4(), (a = [9, 10], b = [11, 12]))

        @test Tables.istable(typeof(store))
        @test Tables.rowaccess(typeof(store))

        rowtbl = Tables.rowtable(store)
        @test length(rowtbl) == 3

        coltbl = Tables.columntable(rowtbl)
        @test length(coltbl.id) == 3
        @test length(coltbl.a) == 3
    end

    @testset "Construct from table" begin
        # Build a table, then construct RowBlobstore from it
        ids = [uuid4(), uuid4()]
        source =
            [(id = ids[1], a = [1, 2], b = [3, 4]), (id = ids[2], a = [5, 6], b = [7, 8])]
        store = DFG.RowBlobstore(:from_table, NT, source)
        @test length(listBlobs(store)) == 2
        @test getBlob(store, ids[1]) == (a = [1, 2], b = [3, 4])
        @test getBlob(store, ids[2]) == (a = [5, 6], b = [7, 8])
    end
end

##==============================================================================
## loadBlob / saveBlob / deleteBlob wrappers for Factors
##==============================================================================
@testset "loadBlob/saveBlob/deleteBlob Factor" begin
    dfg, _, _ = connectivityTestGraph(testDFGAPI, VariableDFG, FactorDFG)
    ds = InMemoryBlobstore(:default)
    addBlobstore!(dfg, ds)

    dataset = rand(UInt8, 200)

    # saveBlob_Factor! with entry_label
    entry = DFG.saveBlob_Factor!(dfg, :x1x2f1, dataset, :factor_data, :default)
    @test entry isa Blobentry
    @test entry.label == :factor_data

    # loadBlob_Factor
    loaded_entry, loaded_blob = DFG.loadBlob_Factor(dfg, :x1x2f1, :factor_data)
    @test loaded_entry == entry
    @test loaded_blob == dataset

    # saveBlob_Factor! with explicit Blobentry
    entry2 = Blobentry(:factor_data_2, :default)
    DFG.saveBlob_Factor!(dfg, :x1x2f1, dataset, entry2)
    loaded_entry2, loaded_blob2 = DFG.loadBlob_Factor(dfg, :x1x2f1, :factor_data_2)
    @test loaded_entry2.label == :factor_data_2
    @test loaded_blob2 == dataset

    # deleteBlob_Factor!
    @test DFG.deleteBlob_Factor!(dfg, :x1x2f1, :factor_data) == 2
    @test !hasFactorBlobentry(dfg, :x1x2f1, :factor_data)

    # Multiple factors can have blobs
    DFG.saveBlob_Factor!(dfg, :x2x3f1, dataset, :another_blob, :default)
    e, b = DFG.loadBlob_Factor(dfg, :x2x3f1, :another_blob)
    @test b == dataset
    @test DFG.deleteBlob_Factor!(dfg, :x2x3f1, :another_blob) == 2

    # Cleanup
    DFG.deleteBlob_Factor!(dfg, :x1x2f1, :factor_data_2)
end

##==============================================================================
## loadBlob / saveBlob / deleteBlob wrappers - Variable (expanded)
##==============================================================================
@testset "loadBlob/saveBlob/deleteBlob Variable (expanded)" begin
    dfg, _, _ = connectivityTestGraph(testDFGAPI, VariableDFG, FactorDFG)
    ds = InMemoryBlobstore(:default)
    addBlobstore!(dfg, ds)

    dataset = rand(UInt8, 300)

    # saveBlob_Variable! with entry_label and kwargs
    entry = DFG.saveBlob_Variable!(
        dfg,
        :x1,
        dataset,
        :var_blob,
        :default;
        description = "test blob",
    )
    @test entry.label == :var_blob
    @test entry.description == "test blob"

    # loadBlob_Variable
    loaded_entry, loaded_blob = DFG.loadBlob_Variable(dfg, :x1, :var_blob)
    @test loaded_entry == entry
    @test loaded_blob == dataset

    # saveBlob_Variable! with explicit Blobentry
    entry2 = Blobentry(:var_blob_2, :default)
    DFG.saveBlob_Variable!(dfg, :x1, dataset, entry2)
    _, blob2 = DFG.loadBlob_Variable(dfg, :x1, :var_blob_2)
    @test blob2 == dataset

    # deleteBlob_Variable!
    @test DFG.deleteBlob_Variable!(dfg, :x1, :var_blob) == 2
    @test DFG.deleteBlob_Variable!(dfg, :x1, :var_blob_2) == 2
end

##==============================================================================
## saveImage_Variable! / loadImage_Variable
##==============================================================================
@testset "saveImage_Variable! / loadImage_Variable" begin
    dfg, _, _ = connectivityTestGraph(testDFGAPI, VariableDFG, FactorDFG)
    ds = InMemoryBlobstore(:default)
    addBlobstore!(dfg, ds)

    # Create a small test "image" (matrix of floats, like a grayscale image)
    # Use N0f8-like values via simple UInt8 matrix to avoid needing Images.jl
    # saveImage_Variable! calls packBlob which needs FileIO save support
    # We test that the interface works by checking that it calls through correctly
    # For a real image test we'd need ImageIO/PNGFiles, so test the error path
    img = rand(Float64, 4, 4)
    @test_throws Exception DFG.saveImage_Variable!(dfg, :x1, img, :test_img, :default)

    # Test loadImage_Variable with a JSON blob that has image mimetype set
    # (tests the dispatch path through unpackBlob(entry, blob))
    json_str = """{"px":[1,2,3]}"""
    blob, _ = DFG.packBlob(format"JSON", json_str)
    entry = Blobentry(:json_as_img, :default; mimetype = MIME("application/json"))
    DFG.saveBlob_Variable!(dfg, :x1, blob, entry)
    loaded_entry, loaded_data = DFG.loadImage_Variable(dfg, :x1, :json_as_img)
    @test loaded_entry.label == :json_as_img
    @test loaded_data == json_str

    DFG.deleteBlob_Variable!(dfg, :x1, :json_as_img)
end
