using Test
using UUIDs
using SHA

testDFGAPI = GraphsDFG

# Helper: compute a Multihash for given data
_mhash(data) = DFG.Multihash(sha2_256, data)

##==============================================================================
## LinkBlobprovider
##==============================================================================
@testset "LinkBlobprovider" begin
    tmpdir = mktempdir()
    try
        link_folder = joinpath(tmpdir, "cas_links")
        source_dir = joinpath(tmpdir, "source_files")
        mkpath(source_dir)

        # Create new LinkBlobprovider
        lp = DFG.LinkBlobprovider(link_folder; label = :links)
        @test lp.label == :links
        @test isdir(link_folder)

        # Write a source data file
        datafile = joinpath(source_dir, "data1.bin")
        test_data = rand(UInt8, 100)
        write(datafile, test_data)

        # putBlob! with a file path — streams hash, creates hardlink
        m = DFG.putBlob!(lp, datafile)
        @test m isa DFG.Multihash

        # putBlob! is idempotent
        m2 = DFG.putBlob!(lp, datafile)
        @test m == m2

        # fetchBlob reads through the CAS layout
        retrieved = fetchBlob(lp, m)
        @test retrieved == test_data

        # fetchBlob for missing hash returns nothing
        @test isnothing(fetchBlob(lp, _mhash(UInt8[0])))

        # hasBlob
        @test hasBlob(lp, m)
        @test !hasBlob(lp, _mhash(UInt8[0]))

        # listBlobs
        hashes = listBlobs(lp)
        @test length(hashes) == 1
        @test m in hashes

        # The CAS file is a hardlink to the original (same inode)
        cas_path = DFG.blobfilename(lp, m)
        @test stat(cas_path).inode == stat(datafile).inode

        # purgeBlob! removes the CAS copy but the original still exists
        @test purgeBlob!(lp, m) == 1
        @test !hasBlob(lp, m)
        @test isfile(datafile)  # original untouched

        # Multiple entries
        datafile2 = joinpath(source_dir, "data2.bin")
        test_data2 = rand(UInt8, 50)
        write(datafile2, test_data2)
        m3 = DFG.putBlob!(lp, datafile2)

        m_re = DFG.putBlob!(lp, datafile)  # re-link first file
        @test m_re == m
        @test length(listBlobs(lp)) == 2
        @test fetchBlob(lp, m) == test_data
        @test fetchBlob(lp, m3) == test_data2
    finally
        rm(tmpdir; force = true, recursive = true)
    end
end

##==============================================================================
## save/load FactorBlob wrappers
##==============================================================================
@testset "saveFactorBlob! / loadFactorBlob" begin
    dfg, _, _ = connectivityTestGraph(testDFGAPI, VariableDFG, FactorDFG)
    ds = DFG.MemoryBlobprovider()  # defaults to :default
    addBlobprovider!(dfg, ds)

    dataset = rand(UInt8, 200)

    # saveFactorBlob! with entry_label (uses :default provider implicitly)
    entry = DFG.saveFactorBlob!(dfg, :x1x2f1, dataset, :factor_data)
    @test entry isa Blobentry
    @test entry.label == :factor_data
    @test entry.provider == :default

    # loadFactorBlob
    loaded_entry, loaded_blob = DFG.loadFactorBlob(dfg, :x1x2f1, :factor_data)
    @test loaded_entry == entry
    @test loaded_blob == dataset

    # saveFactorBlob! with explicit Blobentry
    mh = _mhash(dataset)
    entry2 = Blobentry(:factor_data_2, mh, UInt32(0))
    DFG.saveFactorBlob!(dfg, :x1x2f1, dataset, entry2)
    loaded_entry2, loaded_blob2 = DFG.loadFactorBlob(dfg, :x1x2f1, :factor_data_2)
    @test loaded_entry2.label == :factor_data_2
    @test loaded_blob2 == dataset

    # Delete blobentry (no Layer 3 delete — just remove the pointer)
    deleteFactorBlobentry!(dfg, :x1x2f1, :factor_data)
    @test !hasFactorBlobentry(dfg, :x1x2f1, :factor_data)

    # Multiple factors can have blobs
    DFG.saveFactorBlob!(dfg, :x2x3f1, dataset, :another_blob)
    e, b = DFG.loadFactorBlob(dfg, :x2x3f1, :another_blob)
    @test b == dataset
    deleteFactorBlobentry!(dfg, :x2x3f1, :another_blob)

    # Cleanup
    deleteFactorBlobentry!(dfg, :x1x2f1, :factor_data_2)
end

##==============================================================================
## saveVariableBlob! / loadVariableBlob wrappers (expanded)
##==============================================================================
@testset "saveVariableBlob! / loadVariableBlob (expanded)" begin
    dfg, _, _ = connectivityTestGraph(testDFGAPI, VariableDFG, FactorDFG)
    ds = DFG.MemoryBlobprovider()  # defaults to :default
    addBlobprovider!(dfg, ds)

    dataset = rand(UInt8, 300)

    # saveVariableBlob! with entry_label and kwargs (uses :default implicitly)
    entry = DFG.saveVariableBlob!(dfg, :x1, dataset, :var_blob; description = "test blob")
    @test entry.label == :var_blob
    @test entry.description == "test blob"
    @test entry.provider == :default

    # loadVariableBlob
    loaded_entry, loaded_blob = DFG.loadVariableBlob(dfg, :x1, :var_blob)
    @test loaded_entry == entry
    @test loaded_blob == dataset

    # saveVariableBlob! with explicit Blobentry
    mh = _mhash(dataset)
    entry2 = Blobentry(:var_blob_2, mh, UInt32(0))
    DFG.saveVariableBlob!(dfg, :x1, dataset, entry2)
    _, blob2 = DFG.loadVariableBlob(dfg, :x1, :var_blob_2)
    @test blob2 == dataset

    # Delete blobentries (no Layer 3 delete — just remove the pointer)
    deleteVariableBlobentry!(dfg, :x1, :var_blob)
    deleteVariableBlobentry!(dfg, :x1, :var_blob_2)
end

##==============================================================================
## saveImage_Variable! / loadImage_Variable
##==============================================================================
@testset "saveImage_Variable! / loadImage_Variable" begin
    dfg, _, _ = connectivityTestGraph(testDFGAPI, VariableDFG, FactorDFG)
    ds = DFG.MemoryBlobprovider()  # defaults to :default
    addBlobprovider!(dfg, ds)

    img = rand(Float64, 4, 4)
    entry = DFG.saveImage_Variable!(dfg, :x1, img, :test_img)  # uses :default implicitly
    @test entry.label == :test_img
    @test entry.mimetype == MIME("image/png")
    @test entry.provider == :default

    # Test loadImage_Variable with a JSON blob
    json_str = """{"px":[1,2,3]}"""
    blob, _ = DFG.packBlob(format"JSON", json_str)
    mh = _mhash(blob)
    entry = Blobentry(:json_as_img, mh, UInt32(0); mimetype = MIME("application/json"))
    DFG.saveVariableBlob!(dfg, :x1, blob, entry)
    loaded_entry, loaded_data = DFG.loadImage_Variable(dfg, :x1, :json_as_img)
    @test loaded_entry.label == :json_as_img
    @test loaded_data == json_str

    deleteVariableBlobentry!(dfg, :x1, :json_as_img)
end

##==============================================================================
## CachedBlobprovider
##==============================================================================
@testset "CachedBlobprovider" begin
    @testset "Construction" begin
        local_store = DFG.MemoryBlobprovider(; label = :local)
        remote_store = DFG.MemoryBlobprovider(; label = :remote)
        cached = DFG.CachedBlobprovider(local_store, remote_store; label = :cached)
        @test cached.label == :cached
        @test cached.local_provider === local_store
        @test cached.remote_provider === remote_store

        # Default label
        cached2 = DFG.CachedBlobprovider(local_store, remote_store)
        @test cached2.label == :default
    end

    @testset "putBlob! writes to both" begin
        local_store = DFG.MemoryBlobprovider(; label = :local)
        remote_store = DFG.MemoryBlobprovider(; label = :remote)
        cached = DFG.CachedBlobprovider(local_store, remote_store)

        data = rand(UInt8, 100)
        m = putBlob!(cached, data)
        @test m isa DFG.Multihash

        # Both stores have the blob
        @test hasBlob(local_store, m)
        @test hasBlob(remote_store, m)
        @test fetchBlob(local_store, m) == data
        @test fetchBlob(remote_store, m) == data

        # Idempotent
        @test putBlob!(cached, data) == m
    end

    @testset "fetchBlob caches on miss" begin
        local_store = DFG.MemoryBlobprovider(; label = :local)
        remote_store = DFG.MemoryBlobprovider(; label = :remote)
        cached = DFG.CachedBlobprovider(local_store, remote_store)

        data = rand(UInt8, 80)
        # Put directly into remote only
        m = putBlob!(remote_store, data)
        @test !hasBlob(local_store, m)

        # fetchBlob through cache should fetch and cache locally
        blob = fetchBlob(cached, m)
        @test blob == data
        @test hasBlob(local_store, m)
    end

    @testset "fetchBlob serves from local first" begin
        local_store = DFG.MemoryBlobprovider(; label = :local)
        remote_store = DFG.MemoryBlobprovider(; label = :remote)
        cached = DFG.CachedBlobprovider(local_store, remote_store)

        data = rand(UInt8, 60)
        m = putBlob!(cached, data)

        # Remove from remote — local should still serve
        purgeBlob!(remote_store, m)
        @test !hasBlob(remote_store, m)
        @test fetchBlob(cached, m) == data
    end

    @testset "purgeBlob! removes from both" begin
        local_store = DFG.MemoryBlobprovider(; label = :local)
        remote_store = DFG.MemoryBlobprovider(; label = :remote)
        cached = DFG.CachedBlobprovider(local_store, remote_store)

        data = rand(UInt8, 40)
        m = putBlob!(cached, data)
        @test purgeBlob!(cached, m) == 2  # purged from both local and remote
        @test !hasBlob(local_store, m)
        @test !hasBlob(remote_store, m)
    end

    @testset "hasBlob checks both stores" begin
        local_store = DFG.MemoryBlobprovider(; label = :local)
        remote_store = DFG.MemoryBlobprovider(; label = :remote)
        cached = DFG.CachedBlobprovider(local_store, remote_store)

        data = rand(UInt8, 30)
        m = putBlob!(remote_store, data)

        # Only in remote
        @test hasBlob(cached, m)
        # In neither
        @test !hasBlob(cached, _mhash(UInt8[0]))
    end

    @testset "listBlobs delegates to remote" begin
        local_store = DFG.MemoryBlobprovider(; label = :local)
        remote_store = DFG.MemoryBlobprovider(; label = :remote)
        cached = DFG.CachedBlobprovider(local_store, remote_store)

        d1 = rand(UInt8, 20)
        d2 = rand(UInt8, 25)
        m1 = putBlob!(cached, d1)
        m2 = putBlob!(cached, d2)
        hashes = listBlobs(cached)
        @test length(hashes) == 2
        @test m1 in hashes
        @test m2 in hashes
    end

    @testset "Integration with DFG" begin
        dfg, _, _ = connectivityTestGraph(testDFGAPI, VariableDFG, FactorDFG)
        local_store = DFG.MemoryBlobprovider(; label = :local)
        remote_store = DFG.MemoryBlobprovider(; label = :remote)
        cached = DFG.CachedBlobprovider(local_store, remote_store)  # defaults to :default
        addBlobprovider!(dfg, cached)

        dataset = rand(UInt8, 150)
        entry = DFG.saveVariableBlob!(dfg, :x1, dataset, :cached_blob)  # uses :default
        @test entry isa Blobentry
        @test entry.label == :cached_blob
        @test entry.provider == :default

        loaded_entry, loaded_blob = DFG.loadVariableBlob(dfg, :x1, :cached_blob)
        @test loaded_blob == dataset
        @test loaded_entry == entry

        deleteVariableBlobentry!(dfg, :x1, :cached_blob)
    end

    @testset "CachedBlobprovider with FolderBlobprovider" begin
        tmpdir = mktempdir()
        try
            folder_store = DFG.FolderBlobprovider(tmpdir; label = :folder)
            remote_store = DFG.MemoryBlobprovider(; label = :remote)
            cached = DFG.CachedBlobprovider(folder_store, remote_store; label = :hybrid)

            data = rand(UInt8, 200)
            m = putBlob!(cached, data)

            @test hasBlob(folder_store, m)
            @test hasBlob(remote_store, m)
            @test fetchBlob(cached, m) == data

            # Simulate cache eviction: delete from folder, fetch from remote
            purgeBlob!(folder_store, m)
            @test !hasBlob(folder_store, m)
            blob = fetchBlob(cached, m)
            @test blob == data
            @test hasBlob(folder_store, m)  # re-cached
        finally
            rm(tmpdir; force = true, recursive = true)
        end
    end
end

##==============================================================================
## New-User Flow (Architecture.md §6)
##==============================================================================
@testset "New-User Flow hints" begin
    @testset "Part 1: No providers → helpful error" begin
        dfg, _, _ = connectivityTestGraph(testDFGAPI, VariableDFG, FactorDFG)
        # No blobproviders added — should throw and log a helpful hint
        err = @test_logs (:info, r"no Blobproviders configured.*Hint") try
            getBlobprovider(dfg, :default)
            nothing
        catch e
            e
        end
        @test err isa DFG.LabelNotFoundError
        @test occursin("not found", sprint(showerror, err))
    end

    @testset "Part 2: Duplicate :default → helpful error" begin
        dfg, _, _ = connectivityTestGraph(testDFGAPI, VariableDFG, FactorDFG)
        addBlobprovider!(dfg, DFG.FolderBlobprovider(mktempdir()))
        err = @test_logs (:info, r"Hint") try
            addBlobprovider!(dfg, DFG.MemoryBlobprovider())  # also :default
            nothing
        catch e
            e
        end
        @test err isa DFG.LabelExistsError
    end

    @testset "Part 3: CachedBlobprovider on :default" begin
        dfg, _, _ = connectivityTestGraph(testDFGAPI, VariableDFG, FactorDFG)
        local_store = DFG.FolderBlobprovider(mktempdir())
        remote_store = DFG.MemoryBlobprovider(; label = :remote_backing)
        smart_cache = DFG.CachedBlobprovider(local_store, remote_store)
        addBlobprovider!(dfg, smart_cache)

        data = rand(UInt8, 100)
        entry = DFG.saveVariableBlob!(dfg, :x1, data, :test_blob)  # uses :default
        @test entry.provider == :default
        loaded_entry, loaded_blob = DFG.loadVariableBlob(dfg, :x1, :test_blob)
        @test loaded_blob == data
        deleteVariableBlobentry!(dfg, :x1, :test_blob)
    end

    @testset "Part 4: No :default — explicit routing required" begin
        # Advanced user with only named providers (no :default)
        dfg, _, _ = connectivityTestGraph(testDFGAPI, VariableDFG, FactorDFG)
        addBlobprovider!(dfg, DFG.MemoryBlobprovider(; label = :local))
        addBlobprovider!(dfg, DFG.MemoryBlobprovider(; label = :remote))

        data = rand(UInt8, 80)

        # Implicit :default target should error — forces user to be explicit
        @test_throws DFG.LabelNotFoundError DFG.saveVariableBlob!(dfg, :x1, data, :blob)

        # Explicit routing works
        entry = DFG.saveVariableBlob!(dfg, :x1, data, :blob_local, :local)
        @test entry.provider == :local
        _, blob = DFG.loadVariableBlob(dfg, :x1, :blob_local)
        @test blob == data

        entry2 = DFG.saveVariableBlob!(dfg, :x1, data, :blob_remote, :remote)
        @test entry2.provider == :remote
        _, blob2 = DFG.loadVariableBlob(dfg, :x1, :blob_remote)
        @test blob2 == data

        deleteVariableBlobentry!(dfg, :x1, :blob_local)
        deleteVariableBlobentry!(dfg, :x1, :blob_remote)
    end
end

##==============================================================================
## Fallback Routing (provider as hint)
##==============================================================================
@testset "Fallback routing (provider as hint)" begin
    @testset "getBlob falls back to other providers" begin
        dfg, _, _ = connectivityTestGraph(testDFGAPI, VariableDFG, FactorDFG)
        store_a = DFG.MemoryBlobprovider(; label = :store_a)
        store_b = DFG.MemoryBlobprovider(; label = :store_b)
        addBlobprovider!(dfg, store_a)
        addBlobprovider!(dfg, store_b)

        data = rand(UInt8, 50)
        # Put blob only in store_b
        mh = putBlob!(store_b, data)

        # Create entry that hints at :store_a (which does NOT have the blob)
        entry = Blobentry(:test_fallback, mh, UInt32(0), :store_a)
        addVariableBlobentry!(dfg, :x1, entry)

        # getBlob should fall back to store_b and find it
        blob = getBlob(dfg, entry)
        @test blob == data
    end

    @testset "hasBlob checks all providers" begin
        dfg, _, _ = connectivityTestGraph(testDFGAPI, VariableDFG, FactorDFG)
        store_a = DFG.MemoryBlobprovider(; label = :store_a)
        store_b = DFG.MemoryBlobprovider(; label = :store_b)
        addBlobprovider!(dfg, store_a)
        addBlobprovider!(dfg, store_b)

        data = rand(UInt8, 50)
        mh = putBlob!(store_b, data)

        # Entry hints at :store_a
        entry = Blobentry(:test_has, mh, UInt32(0), :store_a)

        # hasBlob should find it via fallback
        @test hasBlob(dfg, entry)

        # Missing from all providers → false
        fake_entry = Blobentry(:nope, _mhash(UInt8[99]), UInt32(0), :store_a)
        @test !hasBlob(dfg, fake_entry)
    end

    @testset "Layer 1 purgeBlob! on provider" begin
        store = DFG.MemoryBlobprovider(; label = :store)
        data = rand(UInt8, 50)
        mh = putBlob!(store, data)
        @test hasBlob(store, mh)
        @test purgeBlob!(store, mh) == 1
        @test !hasBlob(store, mh)
    end

    @testset "Hint provider is tried first" begin
        dfg, _, _ = connectivityTestGraph(testDFGAPI, VariableDFG, FactorDFG)
        store_a = DFG.MemoryBlobprovider(; label = :store_a)
        store_b = DFG.MemoryBlobprovider(; label = :store_b)
        addBlobprovider!(dfg, store_a)
        addBlobprovider!(dfg, store_b)

        data = rand(UInt8, 50)
        # Put blob in BOTH providers
        mh_a = putBlob!(store_a, data)
        mh_b = putBlob!(store_b, data)
        @test mh_a == mh_b  # CAS: same content → same hash

        # Entry hints at :store_a → should resolve to store_a
        entry = Blobentry(:test_hint_first, mh_a, UInt32(0), :store_a)
        blob = getBlob(dfg, entry)
        @test blob == data
    end

    @testset "Fallback with missing hint provider" begin
        dfg, _, _ = connectivityTestGraph(testDFGAPI, VariableDFG, FactorDFG)
        store_a = DFG.MemoryBlobprovider(; label = :store_a)
        addBlobprovider!(dfg, store_a)

        data = rand(UInt8, 50)
        mh = putBlob!(store_a, data)

        # Entry hints at :nonexistent provider
        entry = Blobentry(:test_missing_hint, mh, UInt32(0), :nonexistent)

        # Should still find the blob via fallback through :store_a
        blob = getBlob(dfg, entry)
        @test blob == data
    end

    @testset "Layer 3 wrappers use fallback" begin
        dfg, _, _ = connectivityTestGraph(testDFGAPI, VariableDFG, FactorDFG)
        store_a = DFG.MemoryBlobprovider(; label = :store_a)
        store_b = DFG.MemoryBlobprovider(; label = :store_b)
        addBlobprovider!(dfg, store_a)
        addBlobprovider!(dfg, store_b)

        data = rand(UInt8, 80)
        # Save via store_a
        entry = DFG.saveVariableBlob!(dfg, :x1, data, :routed_blob, :store_a)
        @test entry.provider == :store_a

        # Manually move blob: delete from store_a, put in store_b
        purgeBlob!(store_a, entry.multihash)
        putBlob!(store_b, data)

        # loadVariableBlob should fall back to store_b
        loaded_entry, loaded_blob = DFG.loadVariableBlob(dfg, :x1, :routed_blob)
        @test loaded_blob == data

        deleteVariableBlobentry!(dfg, :x1, :routed_blob)
    end
end
