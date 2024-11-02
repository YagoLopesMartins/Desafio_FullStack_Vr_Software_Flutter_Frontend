import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

class ProductRegistrationScreen extends StatefulWidget {
  @override
  _ProductRegistrationScreenState createState() =>
      _ProductRegistrationScreenState();
}

class _ProductRegistrationScreenState extends State<ProductRegistrationScreen> {
  static const String baseUrl = 'http://localhost:5000';
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController codigoController = TextEditingController();
  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController custoController = TextEditingController();

  List<Map<String, dynamic>> storePrices = [
    {
      'loja': 'Loja 1',
      'precoVenda': 3.0,
    },
    {
      'loja': 'Loja 2',
      'precoVenda': 5.0,
    }
  ];

// Função para deletar um produto
  Future<void> _deleteProduct() async {
    final codigo = int.tryParse(codigoController.text);
    if (codigo == null) {
      _showAlertDialog('Erro', 'Informe um código válido para excluir');
      return;
    }
    final response = await http.delete(
      Uri.parse('$baseUrl/produtos/$codigo'),
    );

    if (response.statusCode == 201) {
      _showAlertDialog('Sucesso', 'Produto excluído com sucesso');
    } else {
      _showAlertDialog('Erro', 'Produto não encontrado');
    }
  }

  void _showAddProductModal(BuildContext context) {
    String? selectedStore;
    double cost = 0.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.save),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              Text('Alteração/Inclusão de Preço'),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          content: Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  hint: Text('Selecione uma loja'),
                  value: selectedStore,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedStore = newValue;
                    });
                  },
                  items: <String>['Loja 1', 'Loja 2', 'Loja 3']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Custo',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    cost = double.tryParse(value) ?? 0.0;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final String fileExtension =
          pickedFile.path.split('.').last.toLowerCase();

      if (fileExtension == 'png' || fileExtension == 'jpg') {
        setState(() {
          _selectedImage = pickedFile;
        });
      } else {
        _showAlertDialog(
            'Formato inválido', 'Apenas arquivos .png e .jpg são aceitos.');
      }
    }
  }

  Future<void> _createProduct() async {
    final descricao = descricaoController.text;
    final custo = double.tryParse(custoController.text) ?? 0.0;
    String? imagemBase64;

    if (_selectedImage != null) {
      final bytes = await _selectedImage!.readAsBytes();
      imagemBase64 = base64Encode(bytes);
    }

    final data = {
      'descricao': descricao,
      'custo': custo,
      'imagem': imagemBase64,
    };

    String url = '$baseUrl/produtos';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      _showAlertDialog('Sucesso', 'Produto criado com sucesso');
    } else {
      _showAlertDialog('Erro', 'Falha ao criar o produto');
    }
  }

  void _showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: Column(
          children: [
            SizedBox(height: 16),
            AppBar(
              title: Column(
                children: [
                  Divider(thickness: 2, color: Colors.black),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.save, color: Colors.black),
                        onPressed: _createProduct,
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.black),
                        onPressed: _deleteProduct,
                      ),
                      Spacer(),
                      Text('Cadastro de Produto', textAlign: TextAlign.center),
                      Spacer(),
                    ],
                  ),
                  Divider(thickness: 2, color: Colors.black),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtros
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: codigoController,
                          decoration: InputDecoration(
                            labelText: 'Código',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: descricaoController,
                          decoration: InputDecoration(
                            labelText: 'Descrição',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: custoController,
                          decoration: InputDecoration(
                            labelText: 'Custo',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(
                            label: Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.add_circle,
                                      color: Colors.black),
                                  onPressed: () {
                                    _showAddProductModal(context);
                                  },
                                ),
                                Text('Loja', textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                          DataColumn(label: Text('Preço de venda (R\$)')),
                          DataColumn(label: Text('Ações')),
                        ],
                        rows: storePrices.map((store) {
                          return DataRow(
                            cells: [
                              DataCell(Text(store['loja'])),
                              DataCell(Text(store['precoVenda']
                                  .toStringAsFixed(2)
                                  .replaceAll('.', ','))),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        storePrices.remove(store);
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {},
                                  ),
                                ],
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: _selectedImage != null
                        ? Image.file(File(_selectedImage!.path),
                            fit: BoxFit.cover)
                        : Center(child: Text('Imagem padrão')),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(Icons.upload),
                    label: Text('Enviar Imagem'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
