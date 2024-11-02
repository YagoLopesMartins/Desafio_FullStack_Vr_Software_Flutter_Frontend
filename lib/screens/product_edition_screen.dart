import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './../main.dart';

class ProductEditionScreen extends StatefulWidget {
  final int productId;
  ProductEditionScreen({required this.productId});
  @override
  _ProductEditionScreenState createState() => _ProductEditionScreenState();
}

class _ProductEditionScreenState extends State<ProductEditionScreen> {
  List<Map<String, dynamic>> storePrices = [];

  int currentPage = 1;
  int totalPages = 1;
  final int perPage = 10;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController codigoController = TextEditingController();
  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController custoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProductData();
    _fetchStorePrices();
  }

  Future<void> _fetchProductData() async {
    final response = await http
        .get(Uri.parse('http://localhost:5000/produtos/${widget.productId}'));

    if (response.statusCode == 200) {
      final productData = jsonDecode(response.body);
      descricaoController.text = productData['descricao'];
      custoController.text = productData['custo'].toString();
    } else {
      _showAlertDialog('Erro', 'Produto não encontrado');
    }
  }

  Future<void> _deleteProdutoLoja(int id) async {
    final response = await http.delete(
      Uri.parse('http://localhost:5000/produtoloja/$id'),
    );

    if (response.statusCode == 200) {
      _showAlertDialog('Sucesso', 'ProdutoLoja excluído com sucesso.');
      _fetchStorePrices(); // Atualiza a lista
    } else {
      _showAlertDialog('Erro', 'Falha ao excluir ProdutoLoja.');
    }
  }

  Future<void> _fetchStorePrices() async {
    final response = await http.get(Uri.parse(
        'http://localhost:5000/produtoloja?page=$currentPage&per_page=$perPage'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        totalPages = (data['total'] / perPage).ceil();
        storePrices =
            List<Map<String, dynamic>>.from(data['produtos'].map((item) {
          return {
            'id': item['id'],
            'idProduto': item['idProduto'],
            'precoVenda': item['precoVenda'],
            'loja': item['loja'],
          };
        }));
      });
    } else {
      _showAlertDialog('Erro', 'Falha ao carregar preços das lojas');
    }
  }

  void _goToNextPage() {
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
      });
      _fetchStorePrices();
    }
  }

  void _goToPreviousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
      _fetchStorePrices();
    }
  }

  Future<void> _updateProduct() async {
    final descricao = descricaoController.text;
    final custo = double.tryParse(custoController.text) ?? 0.0;

    final data = {
      'descricao': descricao,
      'custo': custo,
    };

    final response = await http.put(
      Uri.parse('http://localhost:5000/produtos/${widget.productId}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      _showAlertDialog('Sucesso', 'Produto atualizado com sucesso');
    } else {
      _showAlertDialog('Erro', 'Falha ao atualizar o produto');
    }
  }

  Future<void> _deleteProduct() async {
    final response = await http.delete(
      Uri.parse('http://localhost:5000/produtos/${widget.productId}'),
    );

    if (response.statusCode == 201) {
      await _showAlertDialog('Sucesso', 'Produto excluído com sucesso')
          .then((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ProductScreen()),
          (Route<dynamic> route) => false,
        );
      });
    } else {
      await _showAlertDialog('Erro', 'Falha ao excluir o produto');
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final String filePath = pickedFile.path;
      final String fileExtension = filePath.split('.').last.toLowerCase();

      if (fileExtension == 'png' || fileExtension == 'jpg') {
        setState(() {
          _selectedImage = File(filePath);
        });
      } else {
        _showAlertDialog(
            'Formato inválido', 'Apenas arquivos .png e .jpg são aceitos.');
      }
    }
  }

  Future<void> _showAlertDialog(String title, String message) async {
    return showDialog(
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

  List<Map<String, dynamic>> lojas = [];

  Future<void> _fetchLojas() async {
    final response = await http.get(Uri.parse('http://localhost:5000/lojas'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        lojas = List<Map<String, dynamic>>.from(data.map((item) => {
              'id': item['id'],
              'descricao': item['loja'],
            }));
      });
    } else {
      _showAlertDialog('Erro', 'Falha ao carregar lojas');
    }
  }

  void _showAddProductModal(BuildContext context) {
    String? selectedStoreId;
    double precoVenda = 0.0;

    _fetchLojas();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.save),
                onPressed: () async {
                  if (selectedStoreId != null && precoVenda > 0) {
                    bool success = await _addProdutoLoja(
                      int.parse(selectedStoreId!),
                      precoVenda,
                    );
                    if (!success) {
                      _showAlertDialog(
                        'Atenção',
                        'Este produto já possui um preço de venda para a loja especificada.',
                      );
                    }
                  }
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
                  value: selectedStoreId,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedStoreId = newValue;
                    });
                  },
                  items: lojas.map<DropdownMenuItem<String>>(
                      (Map<String, dynamic> loja) {
                    return DropdownMenuItem<String>(
                      value: loja['id'].toString(),
                      child: Text(loja['descricao']),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Preço de Venda',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    precoVenda = double.tryParse(value) ?? 0.0;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _addProdutoLoja(int idLoja, double precoVenda) async {
    final response = await http.post(
      Uri.parse('http://localhost:5000/produtoloja'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idLoja': idLoja,
        'idProduto': widget.productId,
        'precoVenda': precoVenda,
      }),
    );

    if (response.statusCode == 400 &&
        jsonDecode(response.body)['message'] ==
            'Este produto já possui um preço de venda para a loja especificada.') {
      return false;
    }

    if (response.statusCode == 201) {
      _showAlertDialog('Sucesso', 'Preço de venda cadastrado com sucesso.');
      _fetchStorePrices();
      return true;
    } else {
      _showAlertDialog('Erro', 'Falha ao cadastrar preço de venda.');
      return false;
    }
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
                        onPressed: _updateProduct,
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
                        rows: storePrices.isNotEmpty
                            ? storePrices.map((store) {
                                final precoVenda = store['precoVenda'];

                                return DataRow(
                                  cells: [
                                    DataCell(Text(store['loja'])),
                                    DataCell(Text(
                                      precoVenda != null
                                          ? precoVenda.toString()
                                          : 'N/A',
                                    )),
                                    DataCell(Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () {
                                            _deleteProdutoLoja(store['id']);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.edit,
                                              color: Colors.blue),
                                          onPressed: () {},
                                        ),
                                      ],
                                    )),
                                  ],
                                );
                              }).toList()
                            : [
                                DataRow(cells: [
                                  DataCell(Text('Nenhum dado encontrado')),
                                  DataCell(Text('')),
                                  DataCell(Text('')),
                                ]),
                              ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _goToPreviousPage,
                        child: Text('Página Anterior'),
                      ),
                      Text('Página $currentPage de $totalPages'),
                      ElevatedButton(
                        onPressed: _goToNextPage,
                        child: Text('Próxima Página'),
                      ),
                    ],
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
                        ? Image.file(_selectedImage!, fit: BoxFit.cover)
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
