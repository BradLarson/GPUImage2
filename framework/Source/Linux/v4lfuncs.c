// These are a series of C functions to bridge to V4L, which has variadic functions, incompatible defines, and union types I couldn't get working in Swift.

#include "libv4l2.h"
#include "v4lfuncs.h"
#include <sys/mman.h>

int v4l2_open_swift(const char *file, int oflag, int arg2)
{
	return v4l2_open(file, oflag, arg2);
}

int v4l2_ioctl_swift(int fd, unsigned long int request, void *arg2)
{
	return v4l2_ioctl(fd, request, arg2);
}

int v4l2_ioctl_S_FMT(int fd, void *arg2)
{
	return v4l2_ioctl(fd, VIDIOC_S_FMT, arg2);
}

int v4l2_ioctl_QUERYCAP(int fd, void *arg2)
{
	return v4l2_ioctl(fd, VIDIOC_QUERYCAP, arg2);
}

int v4l2_ioctl_QBUF(int fd, void *arg2)
{
	return v4l2_ioctl(fd, VIDIOC_QBUF, arg2);
}

int v4l2_ioctl_DQBUF(int fd, void *arg2)
{
	return v4l2_ioctl(fd, VIDIOC_DQBUF, arg2);
}

int v4l2_streamon(int fd)
{
	enum v4l2_buf_type type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	return v4l2_ioctl(fd, VIDIOC_STREAMON, &type);
}

int v4l2_streamoff(int fd)
{
	enum v4l2_buf_type type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	return v4l2_ioctl(fd, VIDIOC_STREAMOFF, &type);
}

struct v4l2_format v4l2_generate_RGB24_format(int width, int height)
{
	struct v4l2_format	fmt;
	fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	fmt.fmt.pix.width       = width;
	fmt.fmt.pix.height      = height;
	fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_RGB24;
	fmt.fmt.pix.field       = V4L2_FIELD_INTERLACED;
	
	return fmt;
}

struct v4l2_format v4l2_generate_YUV420_format(int width, int height)
{
	struct v4l2_format	fmt;
	fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	fmt.fmt.pix.width       = width;
	fmt.fmt.pix.height      = height;
	fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_YUV420;
	fmt.fmt.pix.field       = V4L2_FIELD_SEQ_TB;
	
	return fmt;
}

struct v4l2_format v4l2_generate_YUV422_format(int width, int height)
{
	struct v4l2_format	fmt;
	fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	fmt.fmt.pix.width       = width;
	fmt.fmt.pix.height      = height;
	fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_YUV422P;
	fmt.fmt.pix.field       = V4L2_FIELD_SEQ_TB;
	
	return fmt;
}

struct buffer v4l2_generate_buffer(int fd, int index)
{
	struct v4l2_buffer buf;
	buf.type        = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	buf.memory      = V4L2_MEMORY_MMAP;
	buf.index       = index;
	
	struct buffer buf2;
	
	v4l2_ioctl(fd, VIDIOC_QUERYBUF, &buf);
	buf2.length = buf.length;
	buf2.start = v4l2_mmap(NULL, buf.length,
				      PROT_READ | PROT_WRITE, MAP_SHARED,
				      fd, buf.m.offset);
					  
	
	return buf2;
}

struct v4l2_requestbuffers v4l2_request_buffer_size(int fd, int buffers) 
{
	struct v4l2_requestbuffers req;
	req.count = buffers;
	req.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	req.memory = V4L2_MEMORY_MMAP;
	v4l2_ioctl(fd, VIDIOC_REQBUFS, &req);
	return req;
}

// void v4l2_enqueue_initial_buffers(int fd, int buffers)
// {
// 	for (i = 0; i < n_buffers; ++i) {
//
// 		// buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
// 		// 	    buf.memory = V4L2_MEMORY_MMAP;
// 		// 	    buf.index = i;
// 		// v4l2_ioctl(fd, VIDIOC_QBUF, &buffers);
// 	}
// }

struct v4l2_buffer v4l2_dequeue_buffer(int fd, int index)
{
	struct v4l2_buffer buf;
	buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	buf.memory = V4L2_MEMORY_MMAP;
	buf.index = index;
	v4l2_ioctl(fd, VIDIOC_DQBUF, &buf);
	return buf;
}

void v4l2_enqueue_buffer(int fd, int index)
{
	struct v4l2_buffer buf;
	buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	buf.memory = V4L2_MEMORY_MMAP;
	buf.index = index;
	v4l2_ioctl(fd, VIDIOC_QBUF, &buf);
}
