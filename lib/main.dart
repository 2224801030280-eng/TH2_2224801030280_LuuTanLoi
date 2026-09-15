import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF171717),
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = "0";
  bool _isEquationFinished = false;
  final List<String> _history = [];
  double _memory = 0;

  void _onPressed(String text) {
    setState(() {
      if (text == "C") {
        _display = "0";
        _isEquationFinished = false;
      } else if (text == "CE") {
        _display = _clearCurrentNumber();
        _isEquationFinished = false;
      } else if (text == "⌫") {
        if (_display.length > 1) {
          _display = _display.substring(0, _display.length - 1);
        } else {
          _display = "0";
        }
        _isEquationFinished = false;
      } else if (text == "=") {
        _calculate();
      } else if (["%", "1/x", "x²", "√x", "+/-"].contains(text)) {
        _applyUnary(text);
      } else if (["M+", "M-", "MS"].contains(text)) {
        _applyMemory(text);
      } else {
        if (_isEquationFinished) {
          if (["+", "-", "×", "÷"].contains(text)) {
            _isEquationFinished = false;
          } else {
            _display = "";
            _isEquationFinished = false;
          }
        }

        if (text == ",") {
          final lastNum = _display.split(RegExp(r'[+\-×÷]')).last;
          if (lastNum.contains('.')) return;
          if (_display.isEmpty ||
              ["+", "-", "×", "÷"].contains(_display[_display.length - 1])) {
            _display += "0.";
          } else {
            _display += ".";
          }
          return;
        }

        if (["+", "-", "×", "÷"].contains(text)) {
          if (_display.isEmpty) _display = "0";
          if (["+", "-", "×", "÷"].contains(_display[_display.length - 1])) {
            _display = _display.substring(0, _display.length - 1);
          }
        }

        if (_display == "0" && ![".", "+", "-", "×", "÷"].contains(text)) {
          _display = text;
        } else {
          _display += text;
        }
      }
    });
  }

  void _calculate() {
    try {
      final original = _display;
      String expression = _display
          .replaceAll("×", "*")
          .replaceAll("÷", "/")
          .replaceAll(",", ".");

      GrammarParser p = GrammarParser();
      Expression exp = p.parse(expression);
      ContextModel cm = ContextModel();
      double result = exp.evaluate(EvaluationType.REAL, cm);

      _display = _formatNumber(result);
      _addHistory('$original = $_display');
      _isEquationFinished = true;
    } catch (e) {
      _display = "Loi";
      _isEquationFinished = false;
    }
  }

  String _formatNumber(double value) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(10)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _clearCurrentNumber() {
    final match = RegExp(r'(-?\d*\.?\d+)$').firstMatch(_display);
    if (match == null) return "0";
    final prefix = _display.substring(0, match.start);
    return prefix.isEmpty ? "0" : prefix;
  }

  void _applyUnary(String operation) {
    try {
      final original = _display;
      final expression = _display
          .replaceAll("×", "*")
          .replaceAll("÷", "/")
          .replaceAll(",", ".");
      final value = GrammarParser()
          .parse(expression)
          .evaluate(EvaluationType.REAL, ContextModel());
      double result;
      switch (operation) {
        case "%":
          result = value / 100;
        case "1/x":
          if (value == 0) throw Exception();
          result = 1 / value;
        case "x²":
          result = value * value;
        case "√x":
          if (value < 0) throw Exception();
          result = math.sqrt(value);
        case "+/-":
          result = -value;
        default:
          return;
      }
      _display = _formatNumber(result);
      _addHistory('$operation($original) = $_display');
      _isEquationFinished = true;
    } catch (_) {
      _display = "Loi";
      _isEquationFinished = false;
    }
  }

  void _applyMemory(String operation) {
    final value = double.tryParse(_display.replaceAll(',', '.')) ?? 0;
    if (operation == "M+") _memory += value;
    if (operation == "M-") _memory -= value;
    if (operation == "MS") _memory = value;
  }

  void _addHistory(String item) {
    _history.insert(0, item);
    if (_history.length > 20) _history.removeLast();
  }

  void _showHistory() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF252525),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: 360,
          child: _history.isEmpty
              ? const Center(child: Text('Chưa có lịch sử tính toán'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (_, index) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.history, color: Colors.grey),
                    title: Text(_history[index]),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "2224801030280 - Luu Tan Loi${_memory != 0 ? '  • M' : ''}",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Lịch sử',
            onPressed: _showHistory,
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Text(
                _display,
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w300,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          _buildMinimalKeyboard(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMinimalKeyboard() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildButton("M+", compact: true)),
            Expanded(child: _buildButton("M-", compact: true)),
            Expanded(child: _buildButton("MS", compact: true)),
            const Expanded(child: SizedBox(height: 38)),
          ],
        ),
        _buildRow(["%", "CE", "C", "⌫"]),
        _buildRow(["1/x", "x²", "√x", "÷"]),
        _buildRow(["7", "8", "9", "×"]),
        _buildRow(["4", "5", "6", "-"]),
        _buildRow(["1", "2", "3", "+"]),
        _buildRow(["+/-", "0", ",", "="]),
      ],
    );
  }

  Widget _buildRow(List<String> texts, {bool compact = false}) {
    return Row(
      children: texts
          .map((text) => Expanded(child: _buildButton(text, compact: compact)))
          .toList(),
    );
  }

  Widget _buildButton(
    String text, {
    bool isSpecial = false,
    bool compact = false,
  }) {
    Color bgColor;
    Color textColor = Colors.white;

    if (text == "=") {
      bgColor = const Color(0xFF76C7FF);
      textColor = Colors.black;
    } else if (["0", ","].contains(text)) {
      bgColor = const Color(0xFF2D2D2D);
    } else if ([
      "÷",
      "×",
      "-",
      "+",
      "C",
      "CE",
      "⌫",
      "M+",
      "M-",
      "MS",
    ].contains(text)) {
      bgColor = const Color(0xFF323232);
    } else {
      bgColor = const Color(0xFF3B3B3B);
    }

    return Container(
      height: compact ? 38 : 66,
      padding: const EdgeInsets.all(3),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: () => _onPressed(text),
        child: Text(
          text,
          style: TextStyle(
            fontSize: isSpecial
                ? 28
                : compact
                ? 14
                : 20,
            fontWeight: isSpecial ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
