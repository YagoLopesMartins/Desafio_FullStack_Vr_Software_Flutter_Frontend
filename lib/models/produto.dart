class Produto {
  final int id;
  final String descricao;
  final double custo;
  final double precoVenda;

  Produto(
      {required this.id,
      required this.descricao,
      required this.custo,
      required this.precoVenda});

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id'],
      descricao: json['descricao'],
      custo: json['custo'],
      precoVenda: json['precoVenda'],
    );
  }
}
