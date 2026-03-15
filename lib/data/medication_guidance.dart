class MedicationGuidance
{

  static String calpol(int ageMonths)
  {
    if (ageMonths < 2)
    {
      return "Calpol not recommended under 2 months.";
    }
    else if (ageMonths <= 6)
    {
      return "Calpol: 2.5 ml";
    }
    else if (ageMonths <= 24)
    {
      return "Calpol: 5 ml";
    }
    else if (ageMonths <= 48)
    {
      return "Calpol: 7.5 ml";
    }
    else if (ageMonths <= 72)
    {
      return "Calpol: 10 ml";
    }

    return "Check packaging for correct dosage.";
  }

  static String nurofen(int ageMonths)
  {
    if (ageMonths < 3)
    {
      return "Nurofen not recommended under 3 months.";
    }
    else if (ageMonths <= 12)
    {
      return "Nurofen: 2.5 ml";
    }
    else if (ageMonths <= 36)
    {
      return "Nurofen: 5 ml";
    }
    else if (ageMonths <= 72)
    {
      return "Nurofen: 7.5 ml";
    }

    return "Check packaging for correct dosage.";
  }
}