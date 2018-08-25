

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'intl_generator.dart';


const header = "// Generated Intl message definition file. Do not edit";

Builder autoIntlBuilder(BuilderOptions options) {
  return new LibraryBuilder(new IntlNameGenerator(), generatedExtension: ".intl.dart", header: header);
}