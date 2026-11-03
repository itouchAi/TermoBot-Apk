import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/crypto_vault.dart';
import '../services/telegram_bot_service.dart';

class VaultModal extends StatefulWidget {
  final String currentPin;
  final ValueChanged<String> onUpdatePin;
  final String telegramToken;
  final String telegramChatId;
  final ValueChanged<String> onUpdateToken;
  final ValueChanged<String> onUpdateChatId;

  const VaultModal({
    super.key,
    required this.currentPin,
    required this.onUpdatePin,
    required this.telegramToken,
    required this.telegramChatId,
    required this.onUpdateToken,
    required this.onUpdateChatId,
  });

  @override
  State<VaultModal> createState() => _VaultModalState();
}

class _VaultModalState extends State<VaultModal> {
  bool _isUnlocked = false;
  String _enteredPin = '';
  String? _errorMessage;
  bool _isSendingTest = false;
  String? _testStatus;
  bool _isStatusSuccess = false;

  late TextEditingController _tokenCtrl;
  late TextEditingController _chatIdCtrl;

  @override
  void initState() {
    super.initState();
    _tokenCtrl = TextEditingController(text: widget.telegramToken);
    _chatIdCtrl = TextEditingController(text: widget.telegramChatId);
    _loadEncryptedTokens();
  }

  Future<void> _loadEncryptedTokens() async {
    final encToken = await CryptoVault.getSecureItem('telegram_token');
    final encChatId = await CryptoVault.getSecureItem('telegram_chat_id');
    if (encToken != null && encToken.isNotEmpty) {
      _tokenCtrl.text = encToken;
      widget.onUpdateToken(encToken);
    }
    if (encChatId != null && encChatId.isNotEmpty) {
      _chatIdCtrl.text = encChatId;
      widget.onUpdateChatId(encChatId);
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _chatIdCtrl.dispose();
    super.dispose();
  }

  void _onKeyPress(String digit) {
    if (_enteredPin.length >= 4) return;
    HapticFeedback.selectionClick();
    setState(() {
      _enteredPin += digit;
      _errorMessage = null;
    });

    if (_enteredPin.length == 4) {
      final inputHash = CryptoVault.hashPin(_enteredPin);
      final expectedHash = CryptoVault.hashPin(widget.currentPin.isEmpty ? '1234' : widget.currentPin);

      if (inputHash == expectedHash || _enteredPin == widget.currentPin || widget.currentPin.isEmpty) {
        HapticFeedback.mediumImpact();
        setState(() => _isUnlocked = true);
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage = 'Hatalı PIN! Lütfen şifrenizi kontrol edin.';
          _enteredPin = '';
        });
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
    }
  }

  Future<void> _sendTestAlert() async {
    final token = _tokenCtrl.text.trim();
    final chatId = _chatIdCtrl.text.trim();

    if (token.isEmpty || chatId.isEmpty) {
      setState(() {
        _testStatus = 'Lütfen Bot API Token ve Chat ID alanlarını doldurun.';
        _isStatusSuccess = false;
      });
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isSendingTest = true;
      _testStatus = null;
    });

    // Encrypt and persist tokens into secure vault
    await CryptoVault.setSecureItem('telegram_token', token);
    await CryptoVault.setSecureItem('telegram_chat_id', chatId);
    widget.onUpdateToken(token);
    widget.onUpdateChatId(chatId);

    // Call real Telegram webhook
    final success = await TelegramBotService.sendBoilerAlert(
      botToken: token,
      chatId: chatId,
      eventType: 'test',
      currentTemp: 22.4,
      targetTemp: 23.0,
      isHeating: true,
    );

    if (mounted) {
      setState(() {
        _isSendingTest = false;
        _isStatusSuccess = success;
        _testStatus = success
            ? '✓ Telegram testi başarılı! Bot acil durum test mesajını iletti.'
            : '⚠️ Telegram bağlantı hatası: Token veya Chat ID geçersiz.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF14121E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isUnlocked ? const Color(0xFF10B981).withValues(alpha: 0.2) : const Color(0xFFEF4444).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                        color: _isUnlocked ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kriptografik Donanım Kasası',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          _isUnlocked ? 'AES-GCM 256-bit Kasa Açık' : 'PBKDF2 Korumalı Güvenlik',
                          style: TextStyle(
                            fontSize: 11,
                            color: _isUnlocked ? const Color(0xFF10B981) : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_isUnlocked)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFFB7185)),
                    icon: const Icon(Icons.lock_outline_rounded, size: 16),
                    label: const Text('Kilitle', style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      setState(() {
                        _isUnlocked = false;
                        _enteredPin = '';
                      });
                    },
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
            const SizedBox(height: 18),

            if (!_isUnlocked) ...[
              // Kilitli Ekran: PIN Giriş Noktaları
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? const Color(0xFFF59E0B) : Colors.white24,
                      boxShadow: isFilled
                          ? [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFFFB7185), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                )
              else
                const Text(
                  'Varsayılan PIN: 1234',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              const SizedBox(height: 12),

              _buildKeypad(),
            ] else ...[
              // Kasa Açık: Telegram Bot & Token Ayarları
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kasa açık. Telegram token ve donanım anahtarları yerel bellekte PBKDF2/AES-GCM ile şifreli saklanır.',
                        style: TextStyle(fontSize: 10.5, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _tokenCtrl,
                decoration: InputDecoration(
                  labelText: 'Telegram Bot API Token',
                  labelStyle: const TextStyle(fontSize: 12, color: Colors.white70),
                  hintText: '123456789:ABCdefGHIjkLMNopQRstUVwxyZ',
                  hintStyle: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.vpn_key_rounded, size: 18, color: Color(0xFFF59E0B)),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                onChanged: (v) => widget.onUpdateToken(v),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _chatIdCtrl,
                decoration: InputDecoration(
                  labelText: 'Telegram Chat ID (Grup veya Kullanıcı ID)',
                  labelStyle: const TextStyle(fontSize: 12, color: Colors.white70),
                  hintText: '987654321 veya -100123456789',
                  hintStyle: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.chat_rounded, size: 18, color: Color(0xFF38BDF8)),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                onChanged: (v) => widget.onUpdateChatId(v),
              ),
              const SizedBox(height: 14),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isSendingTest
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(_isSendingTest ? 'Gönderiliyor...' : 'Telegram Test Mesajı Gönder',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: _isSendingTest ? null : _sendTestAlert,
              ),

              if (_testStatus != null) ...[
                const SizedBox(height: 10),
                Text(
                  _testStatus!,
                  style: TextStyle(
                    color: _isStatusSuccess ? const Color(0xFF34D399) : const Color(0xFFFB7185),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '<'],
    ];

    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            if (key.isEmpty) {
              return const SizedBox(width: 68, height: 50);
            }
            if (key == '<') {
              return Container(
                margin: const EdgeInsets.all(4),
                width: 60,
                height: 44,
                child: IconButton(
                  icon: const Icon(Icons.backspace_rounded, color: Colors.white70),
                  onPressed: _onBackspace,
                ),
              );
            }
            return Container(
              margin: const EdgeInsets.all(4),
              width: 60,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF221F2E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white12),
                  ),
                ),
                onPressed: () => _onKeyPress(key),
                child: Text(key, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
