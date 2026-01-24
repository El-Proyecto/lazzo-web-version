import 'dart:math';
import '../constants/event_emojis.dart';

/// Service to suggest emojis based on event title keywords
/// Used when user doesn't select an emoji manually
class EmojiSuggestionService {
  EmojiSuggestionService._();

  static final _random = Random();

  /// Keywords mapped to relevant emojis
  /// Supports Portuguese and English keywords
  static const Map<List<String>, List<String>> _keywordEmojiMap = {
    // Food & Dining
    [
      'restaurant',
      'restaurante',
      'dinner',
      'jantar',
      'lunch',
      'almoço',
      'almoco',
      'food',
      'comida',
      'eat',
      'comer'
    ]: ['🍽️', '🍴', '🥘', '🍲', '🍜', '🥗'],
    ['pizza']: ['🍕'],
    ['burger', 'hamburguer', 'hamburger']: ['🍔'],
    ['sushi', 'japanese', 'japones', 'japonês']: ['🍣', '🍱', '🥢'],
    ['coffee', 'café', 'cafe', 'brunch']: ['☕', '🥐', '🍳'],
    ['breakfast', 'pequeno almoço', 'pequeno-almoço']: ['🥐', '🍳', '☕'],
    ['bar', 'drinks', 'bebidas', 'cocktail', 'cocktails']: [
      '🍹',
      '🍸',
      '🥂',
      '🍺'
    ],
    ['beer', 'cerveja', 'pub']: ['🍺', '🍻'],
    ['wine', 'vinho']: ['🍷', '🍇'],
    ['bbq', 'barbecue', 'churrasco', 'grill']: ['🍖', '🥩', '🔥'],
    ['cake', 'bolo', 'dessert', 'sobremesa', 'doce', 'sweet']: [
      '🍰',
      '🎂',
      '🧁',
      '🍩'
    ],
    ['ice cream', 'gelado', 'sorvete']: ['🍦', '🍨'],
    ['tacos', 'mexican', 'mexicano']: ['🌮', '🌯'],
    ['pasta', 'italian', 'italiano', 'italiana']: ['🍝', '🇮🇹'],
    ['chinese', 'chinês', 'chines']: ['🥡', '🥢', '🍜'],

    // Sports & Activities
    ['football', 'futebol', 'soccer']: ['⚽'],
    ['basketball', 'basquete', 'basquetebol']: ['🏀'],
    ['tennis', 'ténis', 'tenis']: ['🎾'],
    ['golf', 'golfe']: ['⛳'],
    ['swim', 'swimming', 'nadar', 'natação', 'natacao', 'piscina', 'pool']: [
      '🏊',
      '🏊‍♂️',
      '🏊‍♀️'
    ],
    ['gym', 'ginásio', 'ginasio', 'workout', 'treino', 'fitness', 'exercise']: [
      '💪',
      '🏋️',
      '🏃'
    ],
    ['run', 'running', 'corrida', 'correr', 'marathon', 'maratona']: [
      '🏃',
      '🏃‍♂️',
      '🏃‍♀️'
    ],
    ['bike', 'cycling', 'bicicleta', 'ciclismo']: ['🚴', '🚲'],
    ['hike', 'hiking', 'caminhada', 'trilho', 'trail']: ['🥾', '⛰️', '🏔️'],
    ['surf', 'surfing']: ['🏄', '🌊'],
    ['ski', 'skiing', 'esqui', 'snow']: ['⛷️', '🎿', '❄️'],
    ['yoga', 'meditation', 'meditação', 'meditacao']: ['🧘', '🧘‍♀️', '🧘‍♂️'],
    ['paddle', 'padel']: ['🏓', '🎾'],
    ['bowling']: ['🎳'],
    ['fishing', 'pesca', 'pescar']: ['🎣', '🐟'],

    // Entertainment
    ['movie', 'movies', 'filme', 'filmes', 'cinema']: ['🎬', '🍿', '🎥'],
    ['concert', 'concerto', 'show', 'music', 'música', 'musica']: [
      '🎵',
      '🎤',
      '🎸',
      '🎶'
    ],
    ['theater', 'theatre', 'teatro', 'play']: ['🎭'],
    ['game', 'games', 'gaming', 'jogos', 'jogo', 'videogame']: ['🎮', '🕹️'],
    ['board game', 'board games', 'jogos de tabuleiro']: ['🎲', '♟️'],
    ['karaoke']: ['🎤', '🎵'],
    ['festival']: ['🎪', '🎡', '🎢'],
    ['museum', 'museu', 'exhibition', 'exposição', 'exposicao']: ['🏛️', '🎨'],
    ['art', 'arte', 'painting', 'pintura']: ['🎨', '🖼️'],
    ['comedy', 'comédia', 'comedia', 'standup', 'stand-up']: ['😂', '🎭'],

    // Travel & Trips
    [
      'trip',
      'viagem',
      'travel',
      'viajar',
      'vacation',
      'férias',
      'ferias',
      'holiday'
    ]: ['✈️', '🌍', '🗺️', '🧳'],
    ['beach', 'praia']: ['🏖️', '🌊', '☀️', '🏝️'],
    ['mountain', 'montanha', 'serra']: ['⛰️', '🏔️', '🥾'],
    ['camping', 'campismo', 'acampamento', 'camp']: ['🏕️', '⛺', '🔥'],
    ['road trip', 'roadtrip']: ['🚗', '🛣️'],
    ['boat', 'barco', 'sailing', 'vela', 'cruise', 'cruzeiro']: [
      '⛵',
      '🚢',
      '🛥️'
    ],
    ['flight', 'voo', 'airplane', 'avião', 'aviao']: ['✈️', '🛫'],

    // Celebrations & Events
    ['birthday', 'aniversário', 'aniversario', 'bday']: [
      '🎂',
      '🎉',
      '🎈',
      '🥳'
    ],
    ['party', 'festa']: ['🎉', '🥳', '🎊', '💃'],
    ['wedding', 'casamento']: ['💒', '💍', '👰', '🤵'],
    ['graduation', 'formatura']: ['🎓', '👨‍🎓', '👩‍🎓'],
    ['baby shower', 'chá de bebê', 'cha de bebe']: ['👶', '🍼', '🎀'],
    ['christmas', 'natal']: ['🎄', '🎅', '🤶', '🎁'],
    ['new year', 'ano novo', 'reveillon', 'réveillon']: [
      '🎆',
      '🎇',
      '🥂',
      '🎊'
    ],
    ['halloween']: ['🎃', '👻', '🦇'],
    ['easter', 'páscoa', 'pascoa']: ['🐰', '🥚', '🐣'],
    ['valentines', 'valentine', 'namorados', 'são valentim']: [
      '❤️',
      '💕',
      '🌹'
    ],
    ['carnival', 'carnaval']: ['🎭', '🎊', '💃'],

    // Social & Meetings
    ['meeting', 'reunião', 'reuniao']: ['📋', '💼', '📊'],
    ['work', 'trabalho']: ['💼', '🏢', '💻'],
    ['study', 'estudar', 'estudo', 'studying']: ['📚', '📖', '✏️'],
    ['coffee chat', 'café conversa']: ['☕', '💬'],
    ['catchup', 'catch up', 'catch-up', 'conversa']: ['💬', '☕', '🗣️'],
    ['hangout', 'hang out', 'sair', 'passeio']: ['🙌', '😎', '🎉'],
    ['date', 'encontro', 'romantic', 'romântico', 'romantico']: [
      '❤️',
      '🌹',
      '💑'
    ],
    ['friends', 'amigos']: ['👯', '🙌', '😊'],

    // Wellness & Self-care
    ['spa', 'massage', 'massagem']: ['💆', '💆‍♀️', '💆‍♂️', '🧖'],
    ['hair', 'cabelo', 'haircut', 'corte']: ['💇', '💇‍♀️', '💇‍♂️'],
    ['doctor', 'médico', 'medico', 'appointment', 'consulta']: [
      '🩺',
      '👨‍⚕️',
      '👩‍⚕️'
    ],
    ['dentist', 'dentista']: ['🦷', '😁'],

    // Shopping & Errands
    ['shopping', 'compras', 'shop']: ['🛍️', '🛒'],
    ['market', 'mercado', 'supermercado', 'grocery']: ['🛒', '🥬', '🍎'],

    // Nature & Outdoors
    ['picnic', 'piquenique']: ['🧺', '🌳', '🥪'],
    ['park', 'parque', 'garden', 'jardim']: ['🌳', '🌸', '🌺'],
    ['zoo', 'zoológico', 'zoologico']: ['🦁', '🐘', '🦒'],
    ['aquarium', 'aquário', 'aquario']: ['🐠', '🐟', '🦈'],

    // Tech & Learning
    ['workshop', 'course', 'curso', 'class', 'aula']: ['📝', '👨‍🏫', '👩‍🏫'],
    ['hackathon', 'coding', 'programação', 'programacao']: [
      '💻',
      '👨‍💻',
      '👩‍💻'
    ],
    ['conference', 'conferência', 'conferencia']: ['🎤', '📊', '🏛️'],
  };

  /// Suggests an emoji based on the event title
  /// Returns null if no match found (caller should use random)
  static String? suggestEmoji(String title) {
    if (title.isEmpty) return null;

    final lowerTitle = title.toLowerCase();

    for (final entry in _keywordEmojiMap.entries) {
      for (final keyword in entry.key) {
        // Check if keyword is in title (word boundary check for better accuracy)
        if (lowerTitle.contains(keyword)) {
          // Return random emoji from the matched category
          final emojis = entry.value;
          return emojis[_random.nextInt(emojis.length)];
        }
      }
    }

    return null;
  }

  /// Returns a random emoji from the defaults list
  /// Used when no keyword match is found
  static String getRandomEmoji() {
    final defaults = EventEmojis.defaults;
    return defaults[_random.nextInt(defaults.length)];
  }

  /// Suggests an emoji based on title, or returns random if no match
  static String suggestOrRandom(String title) {
    return suggestEmoji(title) ?? getRandomEmoji();
  }
}
