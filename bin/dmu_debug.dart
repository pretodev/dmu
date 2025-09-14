import 'package:dmu/dmu.dart';

void main(List<String> args) {
  final dmu = DartMultiRepoUtility.forDirectory(args.last);

  if (args.first == "add") {
    dmu.add("dio");
  }

  if (args.first == "remove") {
    dmu.remove("dio");
  }

  if (args.first == "pub-get") {
    dmu.pubGet();
  }

  if (args.first == "clean") {
    dmu.clean();
  }

  if (args.first == "deep-clean") {
    dmu.clean(deep: true);
  }
}
