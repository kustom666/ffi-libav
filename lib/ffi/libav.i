%module avcodec
%{
require 'ffi'

module FFI::Libav
  extend FFI::Library

  ffi_lib [ "libavutil.so.54", "libavutil.54.dylib" ]

%}

#define INT64_C(v) v
#define av_const
#define av_always_inline inline
%include "libavutil/avutil.h"
%include "libavutil/pixfmt.h"
%include "libavutil/rational.h"
%include "libavutil/mem.h"
%include "libavutil/attributes.h"
%include "libavutil/mathematics.h"
%include "libavutil/log.h"

%{

  ffi_lib [ "libavcodec.so.54", "libavcodec.54.dylib" ]

%}

/*
#define attribute_deprecated 
#define av_printf_format(a,b)
#define INT64_C(v) v
*/
%include "libavcodec/version.h"
%include "libavcodec/avcodec.h"

%{

  ffi_lib [ "libavformat.so.54", "libavformat.54.dylib" ]

%}

#define av_always_inline inline
%include "libavformat/avio.h"
%include "libavformat/version.h"
%include "libavformat/avformat.h"

%{

  ffi_lib [ "libswscale.so.2", "libswscale.2.dylib" ]

%}

%include "libswscale/swscale.h"

%{
end
%}
