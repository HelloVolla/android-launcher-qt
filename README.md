# Volla Launcher
This is the primary application launcher used in The Volla Phone.

![Volla Launcher](http://volla.online/photos/files/page5-1007-full.jpg)

## Depends on:

* Qt 5.12 or higher
* Android Sdk 21 or higher
* Android NDK r19c or higher
* OpenSSL 1.1.1d
* docker and 10+ GB of disk space (optional)

For convenience, you can use the docker container: `a12e/docker-qt:5.13-android_arm64_v8a` to compile the launcher

## Compilation:

```
$ git clone https://github.com/HelloVolla/android-launcher-qt
$ cd android-launcher-qt
$ git submodule update --init
$ ./build_package
```

The [build_package](build_package) will invoke the script [build_package_android](build_package_android)
inside the `a12e/docker-qt:5.13-android_arm64_v8a` container to build an APK.
Look in the script [build_package_android](build_package_android) for more details on how to compile manually.

## Thanks to
* [androidnative](https://github.com/HelloVolla/androidnative.pri/)
* [openssl](https://github.com/KDAB/android_openssl/)

## License

```
Volla Licence 1.0

Copyright (c) 2020 Hallo Welt Systeme UG

Permission is hereby granted, free of charge, to any person receiving or obtaining a copy
of this software and/or the accompanying respectively associated documentation files
(hereafter the "Software") to use, copy, modify, and/or merge in the Software for personal,
non-commercial use, but not to publish, distribute, sublicense, and/or sell the Software or
a copy of the Software, even in a part.

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
```
