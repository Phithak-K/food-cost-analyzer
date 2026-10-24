export enum UnitType {
  MASS = 'mass', // Base unit: gram (g)
  VOLUME = 'volume', // Base unit: milliliter (ml)
  COUNT = 'count', // Base unit: pieces (pcs)
  UNKNOWN = 'unknown',
}

export class UnitConverter {
  private static readonly massToGram: Record<string, number> = {
    g: 1.0,
    gram: 1.0,
    grams: 1.0,
    kg: 1000.0,
    kilogram: 1000.0,
    kilograms: 1000.0,
    mg: 0.001,
    milligram: 0.001,
    oz: 28.3495,
    ounce: 28.3495,
    lb: 453.592,
    pound: 453.592,
  };

  private static readonly volumeToMl: Record<string, number> = {
    ml: 1.0,
    milliliter: 1.0,
    milliliters: 1.0,
    l: 1000.0,
    liter: 1000.0,
    liters: 1000.0,
    cl: 10.0,
    centiliter: 10.0,
    tsp: 5.0,
    teaspoon: 5.0,
    tbsp: 15.0,
    tablespoon: 15.0,
    cup: 240.0,
    'fl oz': 29.5735,
    floz: 29.5735,
  };

  private static readonly countToPcs: Record<string, number> = {
    pcs: 1.0,
    pc: 1.0,
    piece: 1.0,
    pieces: 1.0,
    unit: 1.0,
    units: 1.0,
    can: 1.0,
    bottle: 1.0,
    pack: 1.0,
    egg: 1.0,
    ฟอง: 1.0,
    ชิ้น: 1.0,
    slice: 1.0,
    doz: 12.0,
    dozen: 12.0,
  };

  static getUnitType(unit: string): UnitType {
    const normalized = unit.trim().toLowerCase();
    if (normalized in this.massToGram) return UnitType.MASS;
    if (normalized in this.volumeToMl) return UnitType.VOLUME;
    if (normalized in this.countToPcs) return UnitType.COUNT;
    return UnitType.UNKNOWN;
  }

  static getBaseUnitName(unit: string): string {
    const type = this.getUnitType(unit);
    switch (type) {
      case UnitType.MASS:
        return 'g';
      case UnitType.VOLUME:
        return 'ml';
      case UnitType.COUNT:
        return 'pcs';
      default:
        return unit.trim().toLowerCase();
    }
  }

  static toBaseUnit(quantity: number, unit: string): number {
    const normalized = unit.trim().toLowerCase();
    if (normalized in this.massToGram) {
      return quantity * this.massToGram[normalized];
    }
    if (normalized in this.volumeToMl) {
      return quantity * this.volumeToMl[normalized];
    }
    if (normalized in this.countToPcs) {
      return quantity * this.countToPcs[normalized];
    }
    return quantity;
  }

  static calculateItemCost(costPerBaseUnit: number, quantityUsed: number, unitUsed: string, yieldPercent = 100.0): number {
    const baseQuantity = this.toBaseUnit(quantityUsed, unitUsed);
    const nominalCost = baseQuantity * costPerBaseUnit;
    const effectiveYield = yieldPercent > 0 ? yieldPercent / 100.0 : 1.0;
    return nominalCost / effectiveYield;
  }
}
