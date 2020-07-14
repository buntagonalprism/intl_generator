// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

const _i18nFunctions = ["Intl.message", "Intl.plural", "Intl.gender"];

final _i18nShorthands = <String, String>{};

String addNameAndArgs(
    String outputStr, String name, MethodDeclaration node, MethodInvocation expression) {
  // If the Intl.message call does not already contain a 'name' parameter, add the element name
  if (!methodInvocationContainsNamedParam(expression, "name")) {
    outputStr = outputStr.replaceAll(RegExp("\\);"), ', name: "$name");');
  }

  // If the Intl.message does not include an 'args' parameter, add the args property
  if (!methodInvocationContainsNamedParam(expression, "args") && node.parameters != null) {
    String argsList = node.parameters.parameters.map((p) => p.identifier.toString()).join(', ');
    outputStr = outputStr.replaceAll(RegExp("\\);"), ', args: [$argsList]);');
  }
  return outputStr;
}

String getIntlCreatorSource(Element sourceElement) {
  String name = sourceElement.displayName;
  AstNode node = nodeForElement(sourceElement);
  if (node is MethodDeclaration) {
    FunctionBody body = node.body;
    if (body is ExpressionFunctionBody) {
      Expression expression = body.expression;
      if (expression is MethodInvocation) {
        // This property uses an Intl function directly
        if (_i18nFunctions.contains(expression.methodName.toString())) {
          return addNameAndArgs(node.toString(), name, node, expression);
        }

        // This property uses a thin-wrapper around an Intl function, such as the `const msg = Intl.message;` shorthand
        // Replace it with the original name
        if (_i18nShorthands.containsKey(expression.methodName.toString())) {
          String wrapperName = expression.methodName.toString();
          String replaceWith = _i18nShorthands[wrapperName];
          String output = node.toString().replaceFirst(RegExp(wrapperName), replaceWith);
          return addNameAndArgs(output, name, node, expression);
        }
      }
    }
  }
  return null;
}

AstNode nodeForElement(Element element) {
  return element.session
      .getParsedLibraryByElement(element.library)
      .getElementDeclaration(element)
      .node;
}

bool methodInvocationContainsNamedParam(MethodInvocation methodInvocation, String paramName) {
  return methodInvocation.argumentList.arguments
      .any((a) => a is NamedExpression && a.name.label.token.value() == paramName);
}

/// Generates internationalisations for the Strings class
class IntlNameGenerator extends Generator {
  const IntlNameGenerator();

  @override
  Future<String> generate(LibraryReader library, _) async {
    var output = StringBuffer();

    for (VariableElement variableElement in library.allElements.whereType<VariableElement>()) {
      final VariableDeclaration node = nodeForElement(variableElement);
      if (_i18nFunctions.contains(node.initializer.toString())) {
        _i18nShorthands[node.name.toString()] = node.initializer.toString();
      }
    }

    for (ClassElement classElement in library.allElements.whereType<ClassElement>()) {
      if (classElement.displayName == "Strings") {
        output.writeln("import 'package:intl/intl.dart';");
        output.writeln("import 'strings.dart';");
        output.writeln();
        output.writeln('class GeneratedStrings implements Strings {');

        // Process strings defined as property getter functions
        for (PropertyAccessorElement propElem in classElement.accessors) {
          String propStr = getIntlCreatorSource(propElem);
          if (propStr != null) {
            output.writeln("  " + propStr);
          }
          // Output any getters returning non-translated strings as-is
          else {
            AstNode node = nodeForElement(propElem);
            if (node is MethodDeclaration) {
              if (node.returnType.toString() == "String") {
                output.writeln("  " + node.toString());
              }
            }
          }
        }

        // Process strings defined as methods
        for (MethodElement methodElem in classElement.methods) {
          String methodStr = getIntlCreatorSource(methodElem);
          if (methodStr != null) {
            output.writeln("  " + methodStr);
          }
        }

        output.writeln('}');
      }
    }

    return '$output';
  }

  @override
  String toString() => 'Auto Intl Generator';
}
