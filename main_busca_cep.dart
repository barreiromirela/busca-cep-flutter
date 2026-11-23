import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TelaBuscaCep(),
    );
  }
}

// -----------------------------------------------------------------------
// 1. Model
// -----------------------------------------------------------------------

class Endereco {
  final String cep;
  final String logradouro;
  final String bairro;
  final String localidade;
  final String uf;

  Endereco({
    required this.cep,
    required this.logradouro,
    required this.bairro,
    required this.localidade,
    required this.uf,
  });

  // Cria o objeto Endereco a partir do JSON retornado pela API do ViaCEP.
  factory Endereco.fromJson(Map<String, dynamic> json) {
    return Endereco(
      cep: json['cep'] ?? '',
      logradouro: json['logradouro'] ?? '',
      bairro: json['bairro'] ?? '',
      localidade: json['localidade'] ?? '',
      uf: json['uf'] ?? '',
    );
  }
}

// -----------------------------------------------------------------------
// 2. Repository
// -----------------------------------------------------------------------

class CepRepository {
  Future<Endereco> consultarCep(String cep) async {
    // Remove qualquer caractere que nao seja numero (ex: hifen do CEP)
    final cepLimpo = cep.replaceAll(RegExp(r'[^0-9]'), '');

    final url = Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Erro ao consultar o CEP (status ${response.statusCode}).');
    }

    final Map<String, dynamic> json = jsonDecode(response.body);

    // A API do ViaCEP retorna {"erro": true} quando o CEP nao existe.
    if (json['erro'] == true) {
      throw Exception('CEP não encontrado.');
    }

    return Endereco.fromJson(json);
  }
}

// -----------------------------------------------------------------------
// 3. View
// -----------------------------------------------------------------------

class TelaBuscaCep extends StatefulWidget {
  const TelaBuscaCep({super.key});

  @override
  State<TelaBuscaCep> createState() => _TelaBuscaCepState();
}

class _TelaBuscaCepState extends State<TelaBuscaCep> {
  final TextEditingController _cepController = TextEditingController();
  final CepRepository _repository = CepRepository();

  Endereco? _endereco;
  bool _carregando = false;
  String? _erro;

  Future<void> _consultarCep() async {
    final cep = _cepController.text.trim();

    if (cep.isEmpty) {
      setState(() {
        _erro = 'Digite um CEP.';
        _endereco = null;
      });
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resultado = await _repository.consultarCep(cep);
      setState(() {
        _endereco = resultado;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = 'Não foi possível encontrar o CEP informado.';
        _endereco = null;
        _carregando = false;
      });
    }
  }

  @override
  void dispose() {
    _cepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Busca de CEP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Campo de texto para o usuario digitar o CEP
            TextField(
              controller: _cepController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'CEP',
                hintText: 'Ex: 01001000',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16.0),

            // Botao de consulta
            ElevatedButton(
              onPressed: _carregando ? null : _consultarCep,
              child: _carregando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Consultar'),
            ),

            const SizedBox(height: 24.0),

            // Mensagem de erro, se houver
            if (_erro != null)
              Text(
                _erro!,
                style: const TextStyle(color: Colors.red),
              ),

            // Labels com os dados retornados pela API
            if (_endereco != null) ...[
              Text('Rua: ${_endereco!.logradouro}'),
              const SizedBox(height: 8.0),
              Text('Bairro: ${_endereco!.bairro}'),
              const SizedBox(height: 8.0),
              Text('Cidade: ${_endereco!.localidade}'),
              const SizedBox(height: 8.0),
              Text('Estado: ${_endereco!.uf}'),
            ],
          ],
        ),
      ),
    );
  }
}
