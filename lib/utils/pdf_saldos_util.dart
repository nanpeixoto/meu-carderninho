import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart'; // No topo do arquivo


class PdfSaldosUtil {
  static Future<void> gerarPdfSaldos(String grupoId, String nomeGrupo) async {
    final dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final pdf = pw.Document();

    // Buscar gastos do grupo
    final gastosSnapshot = await FirebaseFirestore.instance
        .collection('grupos')
        .doc(grupoId)
        .collection('gastos')
        .get();

    final gastos = gastosSnapshot.docs;

    // Calcular saldos por participante
    final Map<String, double> saldos = {};

    for (var gasto in gastos) {
      final valorTotal = (gasto['valor'] ?? 0.0) as double;
      final divididoEntre = List<String>.from(gasto['divididoEntre'] ?? []);
      final valorPorPessoa = valorTotal / divididoEntre.length;

      for (var participanteId in divididoEntre) {
        saldos.update(
          participanteId,
          (valor) => valor + valorPorPessoa,
          ifAbsent: () => valorPorPessoa,
        );
      }
    }

    // Buscar nomes dos usuários
    final usuariosSnapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .where(FieldPath.documentId, whereIn: saldos.keys.toList())
        .get();

    final Map<String, String> nomesUsuarios = {
      for (var doc in usuariosSnapshot.docs)
        doc.id: doc['nome'] ?? 'Desconhecido'
    };

final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');


    // Montar PDF
    pdf.addPage(
  pw.Page(
    margin: const pw.EdgeInsets.all(32),
    build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Saldos do Grupo: $nomeGrupo',
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            ...saldos.entries.map((entry) {
              final nome = nomesUsuarios[entry.key] ?? 'Desconhecido';
              final valor = entry.value;
              final formatado = formatter.format(valor);
              final cor = valor >= 0 ? PdfColors.green : PdfColors.red;
              return pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(nome, style: pw.TextStyle(fontSize: 14)),
                  pw.Text(formatado,
                      style: pw.TextStyle(fontSize: 14, color: cor)),
                ],
              );
            }),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
