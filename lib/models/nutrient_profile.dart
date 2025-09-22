/// Nutrient profile for ingredients that affects plant growth and development
class NutrientProfile {
  // Macronutrients (NPK - Nitrogen, Phosphorus, Potassium)
  final double nitrogen; // N - for leaf growth and green color
  final double phosphorus; // P - for root development and flowering
  final double potassium; // K - for fruit development and disease resistance
  
  // Secondary nutrients
  final double calcium; // Ca - for cell wall strength and fruit quality
  final double magnesium; // Mg - for chlorophyll production
  final double sulfur; // S - for protein synthesis
  
  // Micronutrients (trace elements)
  final double iron; // Fe - for chlorophyll production
  final double manganese; // Mn - for enzyme activation
  final double zinc; // Zn - for growth hormone production
  final double copper; // Cu - for enzyme function
  final double boron; // B - for cell division and flowering
  final double molybdenum; // Mo - for nitrogen fixation
  
  // Plant growth hormones and beneficial compounds
  final double auxins; // Growth hormones for root development
  final double cytokinins; // Growth hormones for cell division
  final double gibberellins; // Growth hormones for stem elongation
  final double enzymes; // Beneficial enzymes for nutrient breakdown
  final double organicAcids; // Natural acids for pH balance
  final double sugars; // Natural sugars for microbial activity
  
  // Plant-specific benefits (0.0 to 1.0 scale)
  final double floweringPromotion; // How much this promotes flowering
  final double fruitingPromotion; // How much this promotes fruiting
  final double rootDevelopment; // How much this promotes root growth
  final double leafGrowth; // How much this promotes leaf development
  final double diseaseResistance; // How much this improves disease resistance
  final double pestResistance; // How much this improves pest resistance
  
  const NutrientProfile({
    // Macronutrients
    this.nitrogen = 0.0,
    this.phosphorus = 0.0,
    this.potassium = 0.0,
    
    // Secondary nutrients
    this.calcium = 0.0,
    this.magnesium = 0.0,
    this.sulfur = 0.0,
    
    // Micronutrients
    this.iron = 0.0,
    this.manganese = 0.0,
    this.zinc = 0.0,
    this.copper = 0.0,
    this.boron = 0.0,
    this.molybdenum = 0.0,
    
    // Growth hormones and compounds
    this.auxins = 0.0,
    this.cytokinins = 0.0,
    this.gibberellins = 0.0,
    this.enzymes = 0.0,
    this.organicAcids = 0.0,
    this.sugars = 0.0,
    
    // Plant benefits
    this.floweringPromotion = 0.0,
    this.fruitingPromotion = 0.0,
    this.rootDevelopment = 0.0,
    this.leafGrowth = 0.0,
    this.diseaseResistance = 0.0,
    this.pestResistance = 0.0,
  });

  factory NutrientProfile.fromMap(Map<String, dynamic> map) => NutrientProfile(
    // Macronutrients
    nitrogen: (map['nitrogen'] as num?)?.toDouble() ?? 0.0,
    phosphorus: (map['phosphorus'] as num?)?.toDouble() ?? 0.0,
    potassium: (map['potassium'] as num?)?.toDouble() ?? 0.0,
    
    // Secondary nutrients
    calcium: (map['calcium'] as num?)?.toDouble() ?? 0.0,
    magnesium: (map['magnesium'] as num?)?.toDouble() ?? 0.0,
    sulfur: (map['sulfur'] as num?)?.toDouble() ?? 0.0,
    
    // Micronutrients
    iron: (map['iron'] as num?)?.toDouble() ?? 0.0,
    manganese: (map['manganese'] as num?)?.toDouble() ?? 0.0,
    zinc: (map['zinc'] as num?)?.toDouble() ?? 0.0,
    copper: (map['copper'] as num?)?.toDouble() ?? 0.0,
    boron: (map['boron'] as num?)?.toDouble() ?? 0.0,
    molybdenum: (map['molybdenum'] as num?)?.toDouble() ?? 0.0,
    
    // Growth hormones and compounds
    auxins: (map['auxins'] as num?)?.toDouble() ?? 0.0,
    cytokinins: (map['cytokinins'] as num?)?.toDouble() ?? 0.0,
    gibberellins: (map['gibberellins'] as num?)?.toDouble() ?? 0.0,
    enzymes: (map['enzymes'] as num?)?.toDouble() ?? 0.0,
    organicAcids: (map['organicAcids'] as num?)?.toDouble() ?? 0.0,
    sugars: (map['sugars'] as num?)?.toDouble() ?? 0.0,
    
    // Plant benefits
    floweringPromotion: (map['floweringPromotion'] as num?)?.toDouble() ?? 0.0,
    fruitingPromotion: (map['fruitingPromotion'] as num?)?.toDouble() ?? 0.0,
    rootDevelopment: (map['rootDevelopment'] as num?)?.toDouble() ?? 0.0,
    leafGrowth: (map['leafGrowth'] as num?)?.toDouble() ?? 0.0,
    diseaseResistance: (map['diseaseResistance'] as num?)?.toDouble() ?? 0.0,
    pestResistance: (map['pestResistance'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toMap() => {
    // Macronutrients
    'nitrogen': nitrogen,
    'phosphorus': phosphorus,
    'potassium': potassium,
    
    // Secondary nutrients
    'calcium': calcium,
    'magnesium': magnesium,
    'sulfur': sulfur,
    
    // Micronutrients
    'iron': iron,
    'manganese': manganese,
    'zinc': zinc,
    'copper': copper,
    'boron': boron,
    'molybdenum': molybdenum,
    
    // Growth hormones and compounds
    'auxins': auxins,
    'cytokinins': cytokinins,
    'gibberellins': gibberellins,
    'enzymes': enzymes,
    'organicAcids': organicAcids,
    'sugars': sugars,
    
    // Plant benefits
    'floweringPromotion': floweringPromotion,
    'fruitingPromotion': fruitingPromotion,
    'rootDevelopment': rootDevelopment,
    'leafGrowth': leafGrowth,
    'diseaseResistance': diseaseResistance,
    'pestResistance': pestResistance,
  };

  /// Calculate total NPK value
  double get totalNPK => nitrogen + phosphorus + potassium;
  
  /// Calculate total macronutrients
  double get totalMacronutrients => nitrogen + phosphorus + potassium + calcium + magnesium + sulfur;
  
  /// Calculate total micronutrients
  double get totalMicronutrients => iron + manganese + zinc + copper + boron + molybdenum;
  
  /// Calculate total growth hormones
  double get totalGrowthHormones => auxins + cytokinins + gibberellins;
  
  /// Calculate total beneficial compounds
  double get totalBeneficialCompounds => enzymes + organicAcids + sugars;
  
  /// Calculate overall plant benefit score
  double get overallPlantBenefit => 
    (floweringPromotion + fruitingPromotion + rootDevelopment + 
     leafGrowth + diseaseResistance + pestResistance) / 6.0;

  /// Add two nutrient profiles together
  NutrientProfile operator +(NutrientProfile other) => NutrientProfile(
    // Macronutrients
    nitrogen: nitrogen + other.nitrogen,
    phosphorus: phosphorus + other.phosphorus,
    potassium: potassium + other.potassium,
    
    // Secondary nutrients
    calcium: calcium + other.calcium,
    magnesium: magnesium + other.magnesium,
    sulfur: sulfur + other.sulfur,
    
    // Micronutrients
    iron: iron + other.iron,
    manganese: manganese + other.manganese,
    zinc: zinc + other.zinc,
    copper: copper + other.copper,
    boron: boron + other.boron,
    molybdenum: molybdenum + other.molybdenum,
    
    // Growth hormones and compounds
    auxins: auxins + other.auxins,
    cytokinins: cytokinins + other.cytokinins,
    gibberellins: gibberellins + other.gibberellins,
    enzymes: enzymes + other.enzymes,
    organicAcids: organicAcids + other.organicAcids,
    sugars: sugars + other.sugars,
    
    // Plant benefits (average them)
    floweringPromotion: (floweringPromotion + other.floweringPromotion) / 2.0,
    fruitingPromotion: (fruitingPromotion + other.fruitingPromotion) / 2.0,
    rootDevelopment: (rootDevelopment + other.rootDevelopment) / 2.0,
    leafGrowth: (leafGrowth + other.leafGrowth) / 2.0,
    diseaseResistance: (diseaseResistance + other.diseaseResistance) / 2.0,
    pestResistance: (pestResistance + other.pestResistance) / 2.0,
  );

  /// Multiply nutrient profile by a factor (for scaling by amount)
  NutrientProfile operator *(double factor) => NutrientProfile(
    // Macronutrients
    nitrogen: nitrogen * factor,
    phosphorus: phosphorus * factor,
    potassium: potassium * factor,
    
    // Secondary nutrients
    calcium: calcium * factor,
    magnesium: magnesium * factor,
    sulfur: sulfur * factor,
    
    // Micronutrients
    iron: iron * factor,
    manganese: manganese * factor,
    zinc: zinc * factor,
    copper: copper * factor,
    boron: boron * factor,
    molybdenum: molybdenum * factor,
    
    // Growth hormones and compounds
    auxins: auxins * factor,
    cytokinins: cytokinins * factor,
    gibberellins: gibberellins * factor,
    enzymes: enzymes * factor,
    organicAcids: organicAcids * factor,
    sugars: sugars * factor,
    
    // Plant benefits (don't scale these as they're already normalized)
    floweringPromotion: floweringPromotion,
    fruitingPromotion: fruitingPromotion,
    rootDevelopment: rootDevelopment,
    leafGrowth: leafGrowth,
    diseaseResistance: diseaseResistance,
    pestResistance: pestResistance,
  );

  /// Get a summary of the nutrient profile for display
  Map<String, String> getSummary() {
    return {
      'NPK': 'N:${nitrogen.toStringAsFixed(1)} P:${phosphorus.toStringAsFixed(1)} K:${potassium.toStringAsFixed(1)}',
      'Flowering': '${(floweringPromotion * 100).toStringAsFixed(0)}%',
      'Fruiting': '${(fruitingPromotion * 100).toStringAsFixed(0)}%',
      'Root Growth': '${(rootDevelopment * 100).toStringAsFixed(0)}%',
      'Leaf Growth': '${(leafGrowth * 100).toStringAsFixed(0)}%',
      'Disease Resistance': '${(diseaseResistance * 100).toStringAsFixed(0)}%',
      'Overall Benefit': '${(overallPlantBenefit * 100).toStringAsFixed(0)}%',
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutrientProfile &&
          runtimeType == other.runtimeType &&
          nitrogen == other.nitrogen &&
          phosphorus == other.phosphorus &&
          potassium == other.potassium &&
          calcium == other.calcium &&
          magnesium == other.magnesium &&
          sulfur == other.sulfur &&
          iron == other.iron &&
          manganese == other.manganese &&
          zinc == other.zinc &&
          copper == other.copper &&
          boron == other.boron &&
          molybdenum == other.molybdenum &&
          auxins == other.auxins &&
          cytokinins == other.cytokinins &&
          gibberellins == other.gibberellins &&
          enzymes == other.enzymes &&
          organicAcids == other.organicAcids &&
          sugars == other.sugars &&
          floweringPromotion == other.floweringPromotion &&
          fruitingPromotion == other.fruitingPromotion &&
          rootDevelopment == other.rootDevelopment &&
          leafGrowth == other.leafGrowth &&
          diseaseResistance == other.diseaseResistance &&
          pestResistance == other.pestResistance;

  @override
  int get hashCode => Object.hashAll([
    nitrogen, phosphorus, potassium, calcium, magnesium, sulfur,
    iron, manganese, zinc, copper, boron, molybdenum,
    auxins, cytokinins, gibberellins, enzymes, organicAcids, sugars,
    floweringPromotion, fruitingPromotion, rootDevelopment,
    leafGrowth, diseaseResistance, pestResistance,
  ]);
}
