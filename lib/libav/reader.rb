require 'ffi/libav'

class Libav::Reader
  include FFI::Libav

  attr_reader :filename, :streams, :av_format_ctx

  def initialize(filename, p={})
    @filename = filename or raise ArgumentError, "No filename"

    Libav.register_all
    @av_format_ctx = FFI::MemoryPointer.new(:pointer)
    rc = avformat_open_input(@av_format_ctx, @filename, nil, nil)
    raise RuntimeError, "avformat_open_input() failed, filename='%s', rc=%d" %
      [filename, rc] if rc != 0
    @av_format_ctx = AVFormatContext.new @av_format_ctx.get_pointer(0)

    rc = avformat_find_stream_info(@av_format_ctx, nil)
    raise RuntimeError, "av_find_stream_info() failed, rc=#{rc}" if rc < 0
    
    initialize_streams(p)
  end

  def dump_format
    FFI::Libav.av_dump_format(@av_format_ctx, 0, @filename, 0)
  end

  # Video duration in (fractional) seconds
  def duration
    @duration ||= @av_format_ctx[:duration].to_f / AV_TIME_BASE
  end

  def each_frame(&block)
    raise ArgumentError, "No block provided" unless block_given?

    packet = AVPacket.new
    # packet = AVPacket.new packet

    while av_read_frame(@av_format_ctx, packet) >= 0
      frame = @streams[packet[:stream_index]].decode_frame(packet)
      rc = frame ? yield(frame) : true
      # av_free_packet(packet)

      break if rc == false
    end

    av_free(packet)
  end

  def default_stream
    @streams[av_find_default_stream_index(@av_format_ctx)]
  end

  def seek(p = {})
    default_stream.seek(p)
  end

  private

  def initialize_streams(p={})
    @streams = @av_format_ctx[:nb_streams].times.map do |i|
      av_stream = AVStream.new \
            @av_format_ctx[:streams].get_pointer(i * FFI::Pointer::SIZE)
      av_codec_ctx = av_stream[:codec]

      case av_codec_ctx[:codec_type]
      when :video
        Libav::Stream::Video.new(:reader => self,
                                  :av_stream => av_stream,
                                  :pixel_format => p[:pixel_format],
                                  :width => p[:width],
                                  :height => p[:height])
      else
        Libav::Stream::Unsupported.new(:reader => self, 
                                        :av_stream => av_stream)
      end
    end
  end
end