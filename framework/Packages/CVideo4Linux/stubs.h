// Need to create non-variadic versions of the V4L functions for them to bridge to Swift

int v4l2_open_swift(const char *file, int oflag, int arg2)
{
	v4l2_open(file, oflag, arg2);
}

int v4l2_ioctl_swift(int fd, unsigned long int request, void *arg2)
{
	v4l2_ioctl(fd, request, arg2);
}

int v4l2_ioctl_S_FMT(int fd, void *arg2)
{
	v4l2_ioctl(fd, VIDIOC_S_FMT, arg2);
}

int v4l2_ioctl_QUERYCAP(int fd, void *arg2)
{
	v4l2_ioctl(fd, VIDIOC_QUERYCAP, arg2);
}