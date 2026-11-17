enum PriceUnit {
  service('pelo serviço'),
  hour('por hora'),
  visit('por visita'),
  day('por diária'),
  piece('por peça');

  const PriceUnit(this.label);
  final String label;
}

class Estimate {
  const Estimate(this.cents, this.unit) : assert(cents > 0);
  final int cents;
  final PriceUnit unit;
  String get amount {
    final reais = (cents ~/ 100).toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return '$reais,${(cents % 100).toString().padLeft(2, '0')}';
  }

  String get label => 'R\$ $amount ${unit.label}';
  Map<String, Object> toJson() => {'cents': cents, 'unit': unit.name};

  static Estimate? fromInput(String input, PriceUnit unit) {
    final cents = parseCents(input);
    return cents == null ? null : Estimate(cents, unit);
  }

  static Estimate? restore(Object? raw) {
    if (raw is! Map) return null;
    final cents = raw['cents'];
    final unit = PriceUnit.values
        .where((u) => u.name == raw['unit'])
        .firstOrNull;
    if (cents is! int || cents <= 0 || unit == null) return null;
    return Estimate(cents, unit);
  }

  static int? parseCents(String input) {
    final raw = input.trim();
    final value = RegExp(r'^\d+\.\d{1,2}$').hasMatch(raw)
        ? raw.replaceFirst('.', ',')
        : raw;
    if (!RegExp(r'^(?:\d+|\d{1,3}(?:\.\d{3})+)(?:,\d{1,2})?$')
        .hasMatch(value)) {
      return null;
    }
    final parts = value.replaceAll('.', '').split(',');
    final digits =
        parts.first + (parts.length == 1 ? '00' : parts[1].padRight(2, '0'));
    final cents = int.tryParse(digits);
    return cents != null && cents > 0 ? cents : null;
  }
}

class JobSummary {
  const JobSummary(this.title, this.description, [this.price]);
  final String title, description;
  final Estimate? price;
  String get priceLabel => price?.label ?? 'A combinar';
  Map<String, Object?> toJson() => {
    'title': title,
    'description': description,
    'price': price?.toJson(),
  };
  static JobSummary? restore(Object? raw) {
    if (raw is! Map ||
        raw['title'] is! String ||
        raw['description'] is! String) {
      return null;
    }
    return JobSummary(
      raw['title'],
      raw['description'],
      Estimate.restore(raw['price']),
    );
  }
}
