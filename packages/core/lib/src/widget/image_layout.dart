part of '../core_helpers.dart';

class ImageLayout extends StatefulWidget {
  final double height;
  final ImageProvider image;
  final String text;
  final double width;
  final String url;
  final void Function(String url) onTapImage;

  ImageLayout(this.image, {this.onTapImage, this.url, this.height, Key key, this.text, this.width})
      : assert(image != null),
        assert(url != null),
        super(key: key);

  @override
  _ImageLayoutState createState() => _ImageLayoutState();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      "ImageLayout($image${height != null ? ', height: $height' : ''}"
      "${text != null ? ', text: "$text"' : ''}"
      "${width != null ? ', width: $width' : ''})";
}

class _ImageLayoutState extends State<ImageLayout> {
  var error;
  double height;
  double width;

  ImageStream _stream;
  ImageStreamListener _streamListener;

  bool get hasDimensions => height != null && height > 0 && width != null;

  @override
  void initState() {
    super.initState();

    height = widget.height;
    width = widget.width;
  }

  @override
  void dispose() {
    super.dispose();

    _stream?.removeListener(_streamListener);
  }

  @override
  Widget build(BuildContext _) {
    if (!hasDimensions && _stream == null) {
      _streamListener = ImageStreamListener(
        (info, isSync) {
          height = info.image.height.toDouble();
          width = info.image.width.toDouble();

          // trigger state change only on async update
          if (!isSync) setState(() {});
        },
        onError: (e, _) =>
            print('[flutter_widget_from_html] Error resolving image: $e'),
      );
      _stream = widget.image.resolve(ImageConfiguration.empty);
      _stream.addListener(_streamListener);
    }

    if (hasDimensions) {
      // we may have dimensions in 3 cases
      // 1. From the beginning, via widget constructor
      // 2. From synchronized image info, immediately in the first build
      // 3. From async update / triggered state change (see above)

      return Container(
        child: GestureDetector(
          child: CustomSingleChildLayout(
            child: Image(image: widget.image, fit: BoxFit.cover),
            delegate: _ImageLayoutDelegate(height: height, width: width),
          ),
          onTap: () {
            widget.onTapImage?.call(widget.url);
          },
          /*gestures: {
            MultipleTapGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                MultipleTapGestureRecognizer>(
                  () => MultipleTapGestureRecognizer(),
                  (instance) {
                    print("sdfsfd");
                //instance..onTap = () => context.parser.onImageTap?.call(src);
              },
            ),
          },*/
        ),
      );
      /*return CustomSingleChildLayout(
        child: Image(image: widget.image, fit: BoxFit.cover),
        delegate: _ImageLayoutDelegate(height: height, width: width),
      );*/
    }

    return widget.text != null ? Text(widget.text) : widget0;
  }
}

class _ImageLayoutDelegate extends SingleChildLayoutDelegate {
  final double height;
  final double ratio;
  final double width;

  _ImageLayoutDelegate({this.height, this.width})
      : assert(height > 0),
        assert(width > 0),
        ratio = width / height;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.tight(getSize(constraints));

  @override
  Size getSize(BoxConstraints bc) {
    final w = width < bc.maxWidth ? width : bc.maxWidth;
    final h = height < bc.maxHeight ? height : bc.maxHeight;
    if (w == width && h == height) return Size(w, h);

    final r = w / h;
    if (r < ratio) return Size(w, w / ratio);

    return Size(h * ratio, h);
  }

  @override
  bool shouldRelayout(_ImageLayoutDelegate other) =>
      height != other.height || width != other.width;
}
