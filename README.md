TCFileViewer
============
by [nevyn](mailto:joachimb@gmail.com), 20121011

You're writing an iOS app. You just want to know what files you have on disk. Xcode's organizer is so slow. NSFileManager invocations in gdb are tiresome.

TCFileViewer to the rescue! Just pull in TCDocumentViewerController.* and the Viewers you need into your project, maybe the thumbnail icons too, and you can do this:

<code><pre>
NSURL *bundlePath = [[NSBundle mainBundle] bundleURL];
UINavigationController *nav = [UINavigationController new];
nav.viewControllers = [TCDirectoryViewController viewControllersForPathComponentsInURL:bundlePath];
</pre></code>

to get this:

<img src="http://cl.ly/image/2t0A2P143q2G/raw" />

Yaay!

Want to support some file format I haven't written a viewer for? Just subclass TCDocumentViewerController and override the public methods, and it'll be picked up automatically. Yaay!