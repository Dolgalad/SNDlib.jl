using Downloads
using Tar
using CodecZlib

"""Download all instances
"""
function download_all_instances()
    archive_cache_path = expanduser("~/.cache/sndlib/archives")
    mkpath(archive_cache_path)
    output_path = joinpath(archive_cache_path, "all_instances_native.tgz")
    url = "http://sndlib.zib.de/download/sndlib-instances-native.tgz"
    Downloads.download(url, output_path)

    # extract the archive
    instance_cache_path = expanduser("~/.cache/sndlib/instances")
    mkpath(instance_cache_path)
    open(GzipDecompressorStream, output_path) do io
        Tar.extract(io, instance_cache_path)
    end

end
