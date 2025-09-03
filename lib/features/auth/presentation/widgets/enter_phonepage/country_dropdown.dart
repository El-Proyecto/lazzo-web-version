import 'package:flutter/material.dart';
import '../../../data/models/country.dart';

class CountryDropdown extends StatefulWidget {
  final List<Country> countries;
  final ValueChanged<Country>? onChanged;
  final Country? initialCountry;

  const CountryDropdown({
    super.key,
    required this.countries,
    this.onChanged,
    this.initialCountry,
  });

  @override
  State<CountryDropdown> createState() => _CountryDropdownState();
}

class _CountryDropdownState extends State<CountryDropdown> {
  late Country selectedCountry;

  @override
  void initState() {
    super.initState();
    selectedCountry = _resolveInitial(widget.initialCountry, widget.countries);
  }

  @override
  void didUpdateWidget(covariant CountryDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    final stillExists = widget.countries.contains(selectedCountry);
    final initialChanged = widget.initialCountry != oldWidget.initialCountry;

    if (!stillExists || initialChanged) {
      setState(() {
        selectedCountry = _resolveInitial(widget.initialCountry, widget.countries);
      });
    }
  }

  Country _resolveInitial(Country? initial, List<Country> list) {
    if (list.isEmpty) {
      throw StateError('CountryDropdown: a lista de países não pode estar vazia.');
    }
    if (initial == null) return list.first;

    final idx = list.indexWhere((c) =>
        c.flag == initial.flag &&
        c.code == initial.code &&
        c.name == initial.name);
    return idx != -1 ? list[idx] : list.first;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<Country>(
      value: selectedCountry,
      isExpanded: true,
      underline: const SizedBox(),
      dropdownColor: const Color(0xFF2B2B2B),
      style: const TextStyle(color: Color(0xFFA5A5A5), fontSize: 16),
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFA5A5A5)),
      // menuMaxHeight: 400, // opcional

      // MENU ABERTO: bandeira + nome + código (com largura finita e escala)
      items: widget.countries.map((c) {
        return DropdownMenuItem<Country>(
          value: c,
          child: SizedBox(
            width: double.infinity, // garante constraints horizontais finitas
            child: FittedBox(
              fit: BoxFit.scaleDown,         // encolhe se faltar espaço
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(c.flag, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  // nome pode cortar com reticências
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220), // segurança extra
                    child: Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    c.code,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                    style: const TextStyle(color: Color(0xFFA5A5A5)),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),

      // ITEM FECHADO: bandeira + código (compacto e elástico)
      selectedItemBuilder: (context) {
        return widget.countries.map((c) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text(c.flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(
                  c.code,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: const TextStyle(fontSize: 14, color: Color(0xFFA5A5A5)),
                ),
              ],
            ),
          );
        }).toList();
      },

      onChanged: (newCountry) {
        if (newCountry == null) return;
        setState(() => selectedCountry = newCountry);
        widget.onChanged?.call(newCountry);
      },
    );
  }
}
