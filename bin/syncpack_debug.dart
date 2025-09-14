import 'package:syncpack/syncpack.dart';

void main(List<String> args) {
  final syncpack = Syncpack.forDirectory(args.last);

  if (args.first == "add") {
    syncpack.add("dio");
  }

  if (args.first == "remove") {
    syncpack.remove("dio");
  }

  if (args.first == "pub-get") {
    syncpack.pubGet();
  }

  if (args.first == "clean") {
    syncpack.clean();
  }

  if (args.first == "deep-clean") {
    syncpack.clean(deep: true);
  }
}
