class PlatformConstants {
  static const Map<String, Map<String, String>> platformData = {
    'Netflix': {
      'subscribers': '260M',
      'description': 'Netflix est un service de divertissement par abonnement de premier plan, proposant des films et des séries télévisées.',
      'url': 'https://www.netflix.com',
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/f/ff/Netflix-new-icon.png',
      'banner': 'https://images.unsplash.com/photo-1574375927938-d5a98e8ffe85?q=80&w=2069&auto=format&fit=crop',
    },
    'Disney+': {
      'subscribers': '150M',
      'description': 'Disney, Pixar, Marvel, Star Wars et National Geographic réunis.',
      'url': 'https://www.disneyplus.com',
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/3/3e/Disney%2B_logo.svg',
      'banner': 'https://images.unsplash.com/photo-1633613286991-611fe299c4be?q=80&w=2070&auto=format&fit=crop',
    },
    'Amazon Prime Video': {
      'subscribers': '200M',
      'description': 'Profitez de films et séries exclusifs, ainsi que des avantages Amazon Prime.',
      'url': 'https://www.primevideo.com',
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/f/f1/Prime_Video.png',
      'banner': 'https://images.unsplash.com/photo-1585647347483-22b66260dfff?q=80&w=2070&auto=format&fit=crop',
    },
    'Apple TV+': {
      'subscribers': '50M',
      'description': 'Des histoires originales des esprits les plus créatifs de la télévision et du cinéma.',
      'url': 'https://tv.apple.com',
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/2/28/Apple_TV_Plus_Logo.svg',
      'banner': 'https://images.unsplash.com/photo-1628155930542-3c7a64e2c833?q=80&w=1974&auto=format&fit=crop',
    },
    'Crunchyroll': {
      'subscribers': '12M',
      'description': 'Le leader mondial du streaming d\'animes, proposant la plus grande bibliothèque de titres.',
      'url': 'https://www.crunchyroll.com',
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/0/08/Crunchyroll_Logo.svg',
      'banner': 'https://images.unsplash.com/photo-1578632738981-433069c3a378?q=80&w=2070&auto=format&fit=crop',
    },
    'HBO': {
      'subscribers': '95M',
      'description': 'HBO propose les séries et films les plus acclamés par la critique, dont Game of Thrones et Succession.',
      'url': 'https://www.hbo.com',
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/d/de/HBO_logo.svg',
      'banner': 'https://images.unsplash.com/photo-1584909066493-57bb51cebfe1?q=80&w=2070&auto=format&fit=crop',
    },
    'Paramount Plus': {
      'subscribers': '63M',
      'description': 'Une montagne de divertissement avec les films de Paramount, CBS et des séries originales.',
      'url': 'https://www.paramountplus.com',
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/a/a5/Paramount_Plus.svg',
      'banner': 'https://images.unsplash.com/photo-1618672267646-7a98920ad8b7?q=80&w=2070&auto=format&fit=crop',
    },
    'Peacock Premium': {
      'subscribers': '30M',
      'description': 'Le service de streaming de NBCUniversal avec des sports en direct, des films et des séries cultes.',
      'url': 'https://www.peacocktv.com',
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/d/d3/Peacock_Logo.svg',
      'banner': 'https://images.unsplash.com/photo-1524712245354-2c4e5e7124c5?q=80&w=2070&auto=format&fit=crop',
    },
  };

  static Map<String, String> getFallbackData(String platformName) {
    return {
      'subscribers': 'N/A',
      'description': 'Découvrez les contenus exclusifs de $platformName sur Eyez. Films, séries et plus encore.',
      'url': '',
      'logo': '',
      'banner': 'https://images.unsplash.com/photo-1485846234645-a62644f84728?q=80&w=2059&auto=format&fit=crop',
    };
  }

  static String normalize(String name) {
    return name.toLowerCase().replaceAll('+', '').replaceAll(' ', '');
  }

  static String? findKey(String platformName) {
    final searchName = normalize(platformName);
    try {
      return platformData.keys.firstWhere((k) {
        final key = normalize(k);
        return key.contains(searchName) || searchName.contains(key);
      });
    } catch (_) {
      return null;
    }
  }
}
