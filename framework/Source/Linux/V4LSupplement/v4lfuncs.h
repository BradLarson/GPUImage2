// Need to create non-variadic versions of the V4L functions for them to bridge to Swift
#include <linux/videodev2.h>

struct buffer {
        void   *start;
        size_t length;
};

int v4l2_open_swift(const char *file, int oflag, int arg2);
int v4l2_ioctl_swift(int fd, unsigned long int request, void *arg2);
int v4l2_ioctl_S_FMT(int fd, void *arg2);
int v4l2_ioctl_QUERYCAP(int fd, void *arg2);
int v4l2_ioctl_QBUF(int fd, void *arg2);
int v4l2_ioctl_DQBUF(int fd, void *arg2);
int v4l2_streamon(int fd);
int v4l2_streamoff(int fd);
struct v4l2_format v4l2_generate_RGB24_format(int width, int height);
struct v4l2_format v4l2_generate_YUV420_format(int width, int height);
struct v4l2_format v4l2_generate_YUV422_format(int width, int height);
struct buffer v4l2_generate_buffer(int fd, int index);
struct v4l2_requestbuffers v4l2_request_buffer_size(int fd, int buffers);
// void v4l2_enqueue_initial_buffers(int fd, int buffers);
struct v4l2_buffer v4l2_dequeue_buffer(int fd, int index);
void v4l2_enqueue_buffer(int fd, int index);
