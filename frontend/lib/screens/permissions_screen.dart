/// Onboarding 2 — Permissions (cahier des charges §3.0). Micro + superposition
/// d'écran, chacune justifiée. Refus possible (« Plus tard ») → mode dégradé.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: Wg.greenTint, borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.lock_rounded, size: 28, color: Wg.green),
          ),
          const SizedBox(height: 22),
          Text('Deux autorisations pour vous protéger',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
          const SizedBox(height: 10),
          const Text(
            "WariGuard n'accède à ces fonctions que pendant un appel suspect. Rien "
            "n'est enregistré.",
            style: TextStyle(fontSize: 14.5, height: 1.5, color: Wg.textDim),
          ),
          const SizedBox(height: 26),
          const _PermCard(
            icon: Icons.mic_none_rounded,
            title: 'Microphone',
            desc: "Pour analyser la voix de l'appelant et détecter les tentatives d'arnaque.",
          ),
          const SizedBox(height: 14),
          const _PermCard(
            icon: Icons.layers_outlined,
            title: "Superposition d'écran",
            desc: "Pour afficher l'alerte par-dessus l'appel, même hors de l'application.",
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: Material(
              color: Wg.green,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => state.grantPermissions(),
                borderRadius: BorderRadius.circular(16),
                child: const Center(
                  child: Text('Autoriser et continuer',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton(
              onPressed: () => state.skipPermissions(),
              child: const Text('Plus tard',
                  style: TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w600, color: Wg.textDim)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermCard extends StatelessWidget {
  const _PermCard({required this.icon, required this.title, required this.desc});

  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: Wg.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(color: Wg.subtle, borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, size: 24, color: Wg.text),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(desc,
                    style: const TextStyle(fontSize: 13, height: 1.45, color: Wg.textDim)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
