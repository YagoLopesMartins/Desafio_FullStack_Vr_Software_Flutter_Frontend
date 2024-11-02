import 'package:flutter/material.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import './screens/product_registration_screen.dart';
import './screens/product_edition_screen.dart';
import 'widgets/pagination.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerenciamento de Loja',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ProductScreen(),
    );
  }
}

class ProductScreen extends StatefulWidget {
  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List<Map<String, dynamic>> products = [];
  int currentPage = 1;
  int totalPages = 1;
  int itemsPerPage = 10;
  bool isLoading = false;

  final TextEditingController codigoController = TextEditingController();
  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController custoController = TextEditingController();
  final TextEditingController precoVendaController = TextEditingController();
  void _onPageChanged(int newPage) {
    setState(() {
      currentPage = newPage;
      products.clear();
      _buscar(newPage);
    });
  }

  @override
  void initState() {
    super.initState();
    _buscar(currentPage);
  }

  Future<void> _deleteProduct(int productId) async {
    const String baseUrl = 'http://localhost:5000';

    final response =
        await http.delete(Uri.parse('$baseUrl/produtos/$productId'));

    if (response.statusCode == 201) {
      setState(() {
        products.removeWhere((product) => product['id'] == productId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produto excluído com sucesso')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir produto')),
      );
    }
  }

  Future<void> _buscar(int page) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    const String baseUrl = 'http://localhost:5000';

    final String codigo = codigoController.text;
    final String descricao = descricaoController.text;
    final String custo = custoController.text;
    final String precoVenda = precoVendaController.text;

    String url = '$baseUrl/produtos?page=$page&per_page=$itemsPerPage';
    if (codigo.isNotEmpty) url += '&codigo=$codigo';
    if (descricao.isNotEmpty) url += '&descricao=$descricao';
    if (custo.isNotEmpty) url += '&custo=$custo';
    if (precoVenda.isNotEmpty) url += '&precoVenda=$precoVenda';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonResponse = convert.jsonDecode(response.body);

      setState(() {
        currentPage = jsonResponse['page'];
        totalPages = jsonResponse['pages'];

        products.addAll((jsonResponse['produtos'] as List)
            .map((product) => {
                  'id': product['id'],
                  'descricao': product['descricao'],
                  'custo': product['custo'],
                  'imagem': product['imagem']
                })
            .toList());
      });
    } else {
      print('[Erro] ao buscar produtos: ${response.statusCode}');
    }

    setState(() {
      isLoading = false;
    });
  }

  void _filterProducts() {
    setState(() {
      currentPage = 1;
      products.clear();
      _buscar(currentPage);
    });
  }

  void _loadMore() {
    if (currentPage < totalPages) {
      _buscar(currentPage + 1);
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
                        icon: Icon(Icons.add_circle, color: Colors.black),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    ProductRegistrationScreen()),
                          );
                        },
                      ),
                      Spacer(),
                      Text('Consulta de Produto', textAlign: TextAlign.center),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: codigoController,
                    decoration: InputDecoration(
                      labelText: 'Código',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _filterProducts(),
                  ),
                ),
                // ),
                SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: descricaoController,
                    decoration: InputDecoration(
                      labelText: 'Descrição',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _filterProducts(),
                  ),
                ),

                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: custoController,
                    decoration: InputDecoration(
                      labelText: 'Custo',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _filterProducts(),
                  ),
                ),
                // ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: precoVendaController,
                    decoration: InputDecoration(
                      labelText: 'Preço de Venda',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _filterProducts(),
                  ),
                ),
                // ),
                SizedBox(width: 4),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Código')),
                    DataColumn(label: Text('Descrição')),
                    DataColumn(label: Text('Custo (R\$)')),
                    DataColumn(label: Text('')),
                  ],
                  rows: products.map((product) {
                    return DataRow(
                      cells: [
                        DataCell(Text(
                            product['id'].toString().padLeft(5, '0') ?? '')),
                        DataCell(Text(product['descricao'] ?? '')),
                        DataCell(
                            Text(product['custo']?.toStringAsFixed(2) ?? '')),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _deleteProduct(product['id']);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ProductEditionScreen(
                                              productId: product['id'])),
                                );
                              },
                            ),
                          ],
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            if (isLoading)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (products.length >= itemsPerPage)
              Pagination(
                currentPage: currentPage,
                totalPages: totalPages,
                onPageChanged: _onPageChanged,
              ),
          ],
        ),
      ),
    );
  }
}
