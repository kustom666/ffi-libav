require 'ffi/libav'

module Libav::Frame; end

class Libav::Frame::Video
  extend Forwardable
  include FFI::Libav

  attr_reader :av_frame, :stream
  attr_accessor :number, :pos
  def_delegator :@av_frame, :[], :[]

  # Initialize a new frame, and optionally allocate memory for the frame data.
  #
  # If only a +:stream+ is provided, the remaining attributes will be copied
  # from that stream.
  #
  # ==== Options
  # * +:stream+ - Libav::Stream this frame belongs to
  # * +:width+  - width of the frame
  # * +:height+ - height of the frame
  # * +:pixel_format+ - format of the frame
  # * +:alloc+ - Allocate space for the frame data [default: true]
  #
  def initialize(p={})
    # Create our frame and alloc space for the frame data
    @av_frame = AVFrame.new

    @stream = p[:stream]
    @av_frame[:width] = p[:width] || @stream && @stream.width
    @av_frame[:height] = p[:height] || @stream && @stream.height
    @av_frame[:format] = p[:pixel_format] || @stream && @stream.pixel_format

    # Allocate the frame's data unless the caller doesn't want us to.
    unless p[:alloc] == false
      av_picture = AVPicture.new @av_frame.pointer
      avpicture_alloc(av_picture, @av_frame[:format], @av_frame[:width],
                      @av_frame[:height])
      ObjectSpace.define_finalizer(self, cleanup_proc(av_picture))
    end
  end

  # define a few reader methods to read the underlying AVFrame
  %w{ width height data linesize }.each do |field|
    define_method(field) { @av_frame[field.to_sym] }
  end

  # define a few accessor methods to read/write fields in the AVFrame
  %w{ pts key_frame }.each do |field|
    define_method(field) { @av_frame[field.to_sym] }
    define_method("#{field}=") { |v| @av_frame[field.to_sym] = v }
  end

  def key_frame?
    @av_frame[:key_frame] != 0
  end

  def pixel_format
    @av_frame[:format]
  end

  # Get the presentation timestamp for this frame in fractional seconds
  def timestamp
    pts * @stream[:time_base].to_f
  end

  # Scale the frame
  #
  # If any of the +:width+, +:height+, or +:pixel_format+ options are not
  # supplied, they will be copied from the +:output_frame+, if provided,
  # otherwise they will be copied from this frame.
  #
  # If no +:scale_ctx+ is provided, one will be allocated and freed within this
  # method.
  #
  # If no +:output_frame+ is provided, this method will allocate a new one.
  #
  # ==== Options
  # * +:width+ - width of the scaled frame
  # * +:height+ - height of the scaled frame
  # * +:pixel_format+ - pixel format of the scaled frame
  # * +:scale_ctx+ - optional software scaling context
  # + +:output_frame+ - optional output frame
  #
  def scale(p={})
    out = p[:output_frame] ||
      self.class.new(:width => p[:width] || width,
                     :height => p[:height] || height,
                     :pixel_format => p[:pixel_format] || pixel_format,
                     :stream => stream)
    ctx = p[:scale_ctx] ||
      sws_getCachedContext(nil, width, height, pixel_format,
                           out.width, out.height, out.pixel_format,
                           SWS_BICUBIC, nil, nil, nil)
    raise NoMemoryError, "sws_getCachedContext() failed" if ctx.nil?

    # Scale the image
    rc = sws_scale(ctx, data, linesize, 0, height, out.data, out.linesize)

    # Free the scale context if one wasn't provided by the caller
    sws_freeContext(ctx) unless p[:scale_ctx]

    # Let's copy a handful of attributes to the scaled frame
    %w{ pts number pos key_frame }.each do |field|
      out.send("#{field}=", send(field))
    end

    # Return our scaled frame
    out
  end

  # Release frame back to buffered stream for re-use
  def release
    stream.release_frame(self)
  end

  private

  # Returns Proc responsible for cleaning up the picture memory when it gets
  # garbage collected.
  def cleanup_proc(picture)
    proc { avpicture_free(picture) }
  end

end
