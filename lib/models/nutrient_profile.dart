import 'package:flutter/foundation.dart';

/// Represents the nutrient profile of an ingredient
@immutable
class NutrientProfile {
  // Macronutrients (g/kg)
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final double calcium;
  final double magnesium;
  final double sulfur;
  
  // Micronutrients (g/kg)
  final double iron;
  final double manganese;
  final double zinc;
  final double copper;
  final double boron;
  final double molybdenum;
  
  // Growth hormones and organic compounds (relative scale 0-1)
  final double auxins;
  final double cytokinins;
  final double gibberellins;
  final double enzymes;
  final double organicAcids;
  final double sugars;
  
  // Plant benefits (percentage 0-1)
  final double floweringPromotion;
  final double fruitingPromotion;
  final double rootDevelopment;
  final double leafGrowth;
  final double diseaseResistance;
  final double pestResistance;

  const NutrientProfile({
    this.nitrogen = 0.0,
    this.phosphorus = 0.0,
    this.potassium = 0.0,
    this.calcium = 0.0,
    this.magnesium = 0.0,
    this.sulfur = 0.0,
    this.iron = 0.0,
    this.manganese = 0.0,
    this.zinc = 0.0,
    this.copper = 0.0,
    this.boron = 0.0,
    this.molybdenum = 0.0,
    this.auxins = 0.0,
    this.cytokinins = 0.0,
    this.gibberellins = 0.0,
    this.enzymes = 0.0,
    this.organicAcids = 0.0,
    this.sugars = 0.0,
    this.floweringPromotion = 0.0,
    this.fruitingPromotion = 0.0,
    this.rootDevelopment = 0.0,
    this.leafGrowth = 0.0,
    this.diseaseResistance = 0.0,
    this.pestResistance = 0.0,
  });

  /// Create from Firestore map
  factory NutrientProfile.fromMap(Map<String, dynamic> map) {
    return NutrientProfile(
      nitrogen: (map['nitrogen'] ?? 0.0).toDouble(),
      phosphorus: (map['phosphorus'] ?? 0.0).toDouble(),
      potassium: (map['potassium'] ?? 0.0).toDouble(),
      calcium: (map['calcium'] ?? 0.0).toDouble(),
      magnesium: (map['magnesium'] ?? 0.0).toDouble(),
      sulfur: (map['sulfur'] ?? 0.0).toDouble(),
      iron: (map['iron'] ?? 0.0).toDouble(),
      manganese: (map['manganese'] ?? 0.0).toDouble(),
      zinc: (map['zinc'] ?? 0.0).toDouble(),
      copper: (map['copper'] ?? 0.0).toDouble(),
      boron: (map['boron'] ?? 0.0).toDouble(),
      molybdenum: (map['molybdenum'] ?? 0.0).toDouble(),
      auxins: (map['auxins'] ?? 0.0).toDouble(),
      cytokinins: (map['cytokinins'] ?? 0.0).toDouble(),
      gibberellins: (map['gibberellins'] ?? 0.0).toDouble(),
      enzymes: (map['enzymes'] ?? 0.0).toDouble(),
      organicAcids: (map['organicAcids'] ?? 0.0).toDouble(),
      sugars: (map['sugars'] ?? 0.0).toDouble(),
      floweringPromotion: (map['floweringPromotion'] ?? 0.0).toDouble(),
      fruitingPromotion: (map['fruitingPromotion'] ?? 0.0).toDouble(),
      rootDevelopment: (map['rootDevelopment'] ?? 0.0).toDouble(),
      leafGrowth: (map['leafGrowth'] ?? 0.0).toDouble(),
      diseaseResistance: (map['diseaseResistance'] ?? 0.0).toDouble(),
      pestResistance: (map['pestResistance'] ?? 0.0).toDouble(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'nitrogen': nitrogen,
      'phosphorus': phosphorus,
      'potassium': potassium,
      'calcium': calcium,
      'magnesium': magnesium,
      'sulfur': sulfur,
      'iron': iron,
      'manganese': manganese,
      'zinc': zinc,
      'copper': copper,
      'boron': boron,
      'molybdenum': molybdenum,
      'auxins': auxins,
      'cytokinins': cytokinins,
      'gibberellins': gibberellins,
      'enzymes': enzymes,
      'organicAcids': organicAcids,
      'sugars': sugars,
      'floweringPromotion': floweringPromotion,
      'fruitingPromotion': fruitingPromotion,
      'rootDevelopment': rootDevelopment,
      'leafGrowth': leafGrowth,
      'diseaseResistance': diseaseResistance,
      'pestResistance': pestResistance,
    };
  }

  /// Add two nutrient profiles together
  NutrientProfile operator +(NutrientProfile other) {
    return NutrientProfile(
      nitrogen: nitrogen + other.nitrogen,
      phosphorus: phosphorus + other.phosphorus,
      potassium: potassium + other.potassium,
      calcium: calcium + other.calcium,
      magnesium: magnesium + other.magnesium,
      sulfur: sulfur + other.sulfur,
      iron: iron + other.iron,
      manganese: manganese + other.manganese,
      zinc: zinc + other.zinc,
      copper: copper + other.copper,
      boron: boron + other.boron,
      molybdenum: molybdenum + other.molybdenum,
      auxins: auxins + other.auxins,
      cytokinins: cytokinins + other.cytokinins,
      gibberellins: gibberellins + other.gibberellins,
      enzymes: enzymes + other.enzymes,
      organicAcids: organicAcids + other.organicAcids,
      sugars: sugars + other.sugars,
      floweringPromotion: floweringPromotion + other.floweringPromotion,
      fruitingPromotion: fruitingPromotion + other.fruitingPromotion,
      rootDevelopment: rootDevelopment + other.rootDevelopment,
      leafGrowth: leafGrowth + other.leafGrowth,
      diseaseResistance: diseaseResistance + other.diseaseResistance,
      pestResistance: pestResistance + other.pestResistance,
    );
  }

  /// Multiply nutrient profile by a scalar
  NutrientProfile operator *(double scalar) {
    return NutrientProfile(
      nitrogen: nitrogen * scalar,
      phosphorus: phosphorus * scalar,
      potassium: potassium * scalar,
      calcium: calcium * scalar,
      magnesium: magnesium * scalar,
      sulfur: sulfur * scalar,
      iron: iron * scalar,
      manganese: manganese * scalar,
      zinc: zinc * scalar,
      copper: copper * scalar,
      boron: boron * scalar,
      molybdenum: molybdenum * scalar,
      auxins: auxins * scalar,
      cytokinins: cytokinins * scalar,
      gibberellins: gibberellins * scalar,
      enzymes: enzymes * scalar,
      organicAcids: organicAcids * scalar,
      sugars: sugars * scalar,
      floweringPromotion: floweringPromotion * scalar,
      fruitingPromotion: fruitingPromotion * scalar,
      rootDevelopment: rootDevelopment * scalar,
      leafGrowth: leafGrowth * scalar,
      diseaseResistance: diseaseResistance * scalar,
      pestResistance: pestResistance * scalar,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NutrientProfile &&
        other.nitrogen == nitrogen &&
        other.phosphorus == phosphorus &&
        other.potassium == potassium &&
        other.calcium == calcium &&
        other.magnesium == magnesium &&
        other.sulfur == sulfur &&
        other.iron == iron &&
        other.manganese == manganese &&
        other.zinc == zinc &&
        other.copper == copper &&
        other.boron == boron &&
        other.molybdenum == molybdenum &&
        other.auxins == auxins &&
        other.cytokinins == cytokinins &&
        other.gibberellins == gibberellins &&
        other.enzymes == enzymes &&
        other.organicAcids == organicAcids &&
        other.sugars == sugars &&
        other.floweringPromotion == floweringPromotion &&
        other.fruitingPromotion == fruitingPromotion &&
        other.rootDevelopment == rootDevelopment &&
        other.leafGrowth == leafGrowth &&
        other.diseaseResistance == diseaseResistance &&
        other.pestResistance == pestResistance;
  }

  @override
  int get hashCode {
    return Object.hash(
      nitrogen,
      phosphorus,
      potassium,
      calcium,
      magnesium,
      sulfur,
      iron,
      manganese,
      zinc,
      copper,
      boron,
      molybdenum,
      auxins,
      cytokinins,
      gibberellins,
      enzymes,
      organicAcids,
      sugars,
      Object.hash(
        floweringPromotion,
        fruitingPromotion,
        rootDevelopment,
        leafGrowth,
        diseaseResistance,
        pestResistance,
      ),
    );
  }
}
