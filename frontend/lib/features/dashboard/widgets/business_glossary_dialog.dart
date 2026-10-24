import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/file_downloader.dart';

/// Data class representing a restaurant business & menu engineering glossary term.
class GlossaryTerm {
  final String id;
  final String title;
  final String englishName;
  final String category;
  final IconData icon;
  final Color color;
  final String oneLiner;
  final String details;
  final String? formula;
  final String? benchmark;
  final String example;
  final String actionTip;

  const GlossaryTerm({
    required this.id,
    required this.title,
    required this.englishName,
    required this.category,
    required this.icon,
    required this.color,
    required this.oneLiner,
    required this.details,
    this.formula,
    this.benchmark,
    required this.example,
    required this.actionTip,
  });
}

class BusinessGlossary {
  static const List<GlossaryTerm> terms = [
    GlossaryTerm(
      id: 'food_cost_pct',
      title: 'Food Cost Percentage (สัดส่วนต้นทุนอาหาร %)',
      englishName: 'Food Cost %',
      category: 'ต้นทุน & กำไร',
      icon: Icons.pie_chart_rounded,
      color: AppTheme.primaryNeon,
      oneLiner: 'จากราคาขาย 100 บาท เราจ่ายค่าวัตถุดิบไปกี่บาท',
      details:
          'ตัวชี้วัดสุขภาพทางการเงินที่สำคัญที่สุดของร้านอาหาร แสดงสัดส่วนเงินที่ถูกใช้ไปกับวัตถุดิบที่ลงในจานเทียบกับราคาขายหน้าร้าน ไม่รวมค่าเช่าและค่าแรงงานพนักงาน',
      formula: '(ต้นทุนวัตถุดิบรวมต่อจาน ÷ ราคาขายหน้าร้าน) × 100',
      benchmark: 'ร้านอาหารทั่วไปควรคุมให้อยู่ที่ 28% – 35% (หากเกิน 35% เริ่มเข้าสู่โซนอันตราย)',
      example:
          'ข้าวกะเพราเนื้อไข่ดาว ขายจานละ 120 บาท ต้นทุนเนื้อ ข้าว ไข่ และเครื่องปรุงรวม 36 บาท คิดเป็น Food Cost = (36 ÷ 120) × 100 = 30.0% (อยู่ในเกณฑ์ปลอดภัย)',
      actionTip:
          'ถ้าเมนูไหน Food Cost เกิน 35% อย่าเพิ่งรีบขึ้นราคาอย่างเดียว ให้ตรวจการตักชั่งตวง (Portion Control) และของเสียจากการหั่นแต่ง (Waste) ก่อนเสมอ',
    ),
    GlossaryTerm(
      id: 'contribution_margin',
      title: 'Contribution Margin (กำไรส่วนเกินต่อจาน / มาร์จิน)',
      englishName: 'Contribution Margin (CM)',
      category: 'ต้นทุน & กำไร',
      icon: Icons.account_balance_wallet_rounded,
      color: AppTheme.success,
      oneLiner: 'ขายจานนี้ได้ 1 จาน เหลือกำไรเป็นเงินสดใส่กระเป๋ากี่บาท',
      details:
          'จำนวนเงินสดสุทธิที่ได้รับจากการขายอาหารแต่ละจานหลังจากหักต้นทุนวัตถุดิบออกแล้ว เงินก้อนนี้จะถูกนำไปจ่ายค่าเช่า ค่าน้ำค่าไฟ เงินเดือนพนักงาน และเหลือกำไรสุทธิเข้ากระเป๋าเจ้าของร้าน',
      formula: 'ราคาขายหน้าร้าน - ต้นทุนวัตถุดิบรวมต่อจาน',
      benchmark: 'ยิ่งสูงยิ่งดี ควรคำนึงถึง "ตัวเงินบาทจริง" ควบคู่กับ "เปอร์เซ็นต์"',
      example:
          'สเต็กเนื้อวากิว ขาย 650 บาท ต้นทุน 260 บาท (Food Cost 40% ซึ่งดูเหมือนสูง) แต่เหลือเงินสดกำไรถึง 390 บาทต่อจาน ดีกว่าขายชามะนาวที่ Food Cost 15% ขาย 40 บาท เหลือกำไรแค่ 34 บาท',
      actionTip:
          'ร้านอาหารไม่สามารถนำเปอร์เซ็นต์ไปจ่ายค่าเช่าร้านได้ แต่ใช้เงินบาทสดๆ จ่าย! ดังนั้นให้โฟกัสเมนูที่สร้างเงินบาท (Margin บาท) สูงๆ เป็นหลัก',
    ),
    GlossaryTerm(
      id: 'matrix_overview',
      title: 'Menu Engineering Matrix (เมทริกซ์วิเคราะห์เมนู Kasavana & Smith)',
      englishName: 'Menu Engineering Matrix',
      category: 'เมทริกซ์ 4 กลุ่ม',
      icon: Icons.grid_view_rounded,
      color: AppTheme.accent,
      oneLiner: 'เครื่องมือแบ่งเมนูอาหารเป็น 4 กลุ่มตาม "ยอดขาย" และ "กำไร"',
      details:
          'คิดค้นโดย Michael Kasavana และ Donald Smith จากมหาวิทยาลัย Michigan State เป็นกรอบการตัดสินใจเชิงกลยุทธ์ โดยใช้เส้นตัดค่าเฉลี่ยของร้าน (Average Margin และ Average Units Sold) แบ่งอาหารออกเป็น 4 โซน: Stars, Plowhorses, Puzzles, Dogs',
      formula: 'แกน X = ปริมาณขาย (Sales Volume) | แกน Y = กำไรส่วนเกิน (Contribution Margin)',
      benchmark: 'ร้านอาหารที่ดีควรมีเมนูส่วนใหญ่อยู่ในกลุ่ม Stars และ Plowhorses',
      example:
          'ร้านคำนวณจุดตัดเฉลี่ยได้: กำไรเฉลี่ย 150 บาท/จาน และยอดขายเฉลี่ย 200 จาน/เดือน เมนูไหนขายได้ 350 จาน กำไร 180 บาท จะถูกจัดเป็น Star ทันที',
      actionTip:
          'ควรทบทวนตำแหน่งของเมนูใน Matrix ทุกๆ 1-3 เดือน หรือเมื่อมีการเปลี่ยนแปลงราคาต้นทุนวัตถุดิบครั้งใหญ่',
    ),
    GlossaryTerm(
      id: 'stars',
      title: '⭐ Stars (ดาวเด่น / ขายดีมาก + กำไรสูงมาก)',
      englishName: 'Stars (High Margin / High Volume)',
      category: 'เมทริกซ์ 4 กลุ่ม',
      icon: Icons.star_rounded,
      color: AppTheme.starGreen,
      oneLiner: 'เมนูพระเอกของร้าน ลูกค้าสั่งเยอะ แถมทำกำไรคุ้มค่าเหนื่อย',
      details:
          'สุดยอดเมนูที่สร้างรายได้และกำไรหลักให้ร้าน อาหารกลุ่มนี้เป็นที่นิยมของลูกค้าอย่างต่อเนื่องและสร้างผลตอบแทนต่อจานสูงกว่าค่าเฉลี่ยของร้าน',
      formula: 'ยอดขายสูงกว่าค่าเฉลี่ย (High Volume) + กำไรสูงกว่าค่าเฉลี่ย (High Margin)',
      benchmark: 'ควรรักษาให้มีสัดส่วนยอดขายอย่างน้อย 30% - 40% ของทั้งร้าน',
      example:
          'ข้าวซอยไก่สูตรพิเศษ หรือ ซี่โครงหมูบาร์บีคิวรมควัน ที่ลูกค้าประจำต้องสั่งซ้ำ และร้านคำนวณต้นทุนมาอย่างดีเยี่ยม',
      actionTip:
          'กลยุทธ์: 1) ห้ามลดคุณภาพหรือขนาดเด็ดขาด 2) วางตำแหน่งเด่นสุดในเล่มเมนู (มุมขวาบน หรือจุดรวมสายตา) 3) ควบคุมความเร็วในการออกอาหารให้คงเส้นคงวา',
    ),
    GlossaryTerm(
      id: 'plowhorses',
      title: '🐎 Plowhorses (ม้าศึก / ขายดีมาก + แต่กำไรต่ำ)',
      englishName: 'Plowhorses (Low Margin / High Volume)',
      category: 'เมทริกซ์ 4 กลุ่ม',
      icon: Icons.bolt_rounded,
      color: AppTheme.plowhorseAmber,
      oneLiner: 'เมนูยอดฮิตมหาชน ลูกค้าชอบสั่ง แต่ร้านเหลือกำไรบางเฉียบ',
      details:
          'เมนูขวัญใจมหาชนที่ช่วยดึงดูดลูกค้าเข้าร้าน ยอดขายถล่มทลายแต่กำไรต่อจานต่ำกว่าค่าเฉลี่ย ทำให้เหนื่อยแรงครัวแต่เงินเหลือเข้ากระเป๋าน้อยกว่าที่ควรจะเป็น',
      formula: 'ยอดขายสูงกว่าค่าเฉลี่ย (High Volume) + กำไรต่ำกว่าค่าเฉลี่ย (Low Margin)',
      benchmark: 'จำเป็นต้องมีเพื่อดึงทราฟฟิก แต่ต้องระวังไม่ให้ต้นทุนวัตถุดิบบวมจนขาดทุน',
      example:
          'ผัดไทยกุ้งสด หรือ ข้าวกะเพราหมูสับราคาประหยัด ที่สั่งกันทุกโต๊ะ แต่เนื่องจากกุ้งและเนื้อสัตว์ราคาสูง ทำให้เหลือกำไรจานละไม่กี่สิบบาท',
      actionTip:
          'กลยุทธ์: 1) ทยอยขยับราคาขึ้นทีละ 5-10 บาทแบบเนียนๆ 2) ปรับสูตรลดวัตถุดิบแพงลงเล็กน้อยแล้วเพิ่มเครื่องเคียงต้นทุนต่ำ 3) จับคู่เซ็ต (Combo) กับเครื่องดื่มกำไรสูง',
    ),
    GlossaryTerm(
      id: 'puzzles',
      title: '🧩 Puzzles (ปริศนา / กำไรสูงปัง + แต่ขายน้อย)',
      englishName: 'Puzzles (High Margin / Low Volume)',
      category: 'เมทริกซ์ 4 กลุ่ม',
      icon: Icons.extension_rounded,
      color: AppTheme.puzzlePurple,
      oneLiner: 'เมนูของดีกำไรเยี่ยม แต่ลูกค้าแทบไม่สั่ง หรือไม่รู้ว่ามี',
      details:
          'เมนูที่มีอัตราทำกำไรยอดเยี่ยมมาก แต่ยอดขายต่ำกว่าค่าเฉลี่ย อาจเกิดจากการตั้งชื่อไม่ดึงดูด รูปภาพไม่น่ากิน ตำแหน่งในเล่มเมนูหลบมุม หรือราคาดูสูงเกินไปจนลูกค้าไม่กล้าลอง',
      formula: 'ยอดขายต่ำกว่าค่าเฉลี่ย (Low Volume) + กำไรสูงกว่าค่าเฉลี่ย (High Margin)',
      benchmark: 'โอกาสทองในการเพิ่มกำไรสุทธิ หากดันยอดขายขึ้นได้ ร้านจะมีกำไรเพิ่มขึ้นทันที',
      example:
          'ปลากะพงอบสมุนไพรซอสไวน์ขาว กำไรต่อจานสูงถึง 250 บาท แต่ในเล่มเมนูไม่มีรูปภาพประกอบและซ่อนอยู่หน้าท้ายๆ ทำให้ขายได้แค่สัปดาห์ละ 5 จาน',
      actionTip:
          'กลยุทธ์: 1) เปลี่ยนชื่อเมนูให้น่ากินขึ้น 2) เพิ่มรูปถ่ายอาหารขนาดใหญ่ 3) ย้ายตำแหน่งมาไว้หน้าแรก 4) อบรมพนักงานเสิร์ฟให้แนะนำเป็น "เมนูแนะนำประจำวัน"',
    ),
    GlossaryTerm(
      id: 'dogs',
      title: '🐶 Dogs (สุนัขจนตรอก / ขายน้อย + กำไรต่ำ)',
      englishName: 'Dogs (Low Margin / Low Volume)',
      category: 'เมทริกซ์ 4 กลุ่ม',
      icon: Icons.pets_rounded,
      color: AppTheme.dogRose,
      oneLiner: 'เมนูปราบเซียน ขายก็ไม่ออก แถมกำไรก็น้อย เปลืองพื้นที่ตู้เย็น',
      details:
          'เมนูที่สร้างภาระให้ร้านอาหาร ทั้งขายไม่ดีและยังทำกำไรต่ำ มักสร้างปัญหาวัตถุดิบตกค้าง เน่าเสีย และเพิ่มภาระความซับซ้อนให้พนักงานในครัว',
      formula: 'ยอดขายต่ำกว่าค่าเฉลี่ย (Low Volume) + กำไรต่ำกว่าค่าเฉลี่ย (Low Margin)',
      benchmark: 'ควรลดจำนวนเมนูกลุ่มนี้ให้เหลือน้อยที่สุดในร้าน',
      example:
          'ซุปฟักทองทรัฟเฟิล ที่ต้องเตรียมวัตถุดิบเฉพาะตัว แต่ทั้งเดือนขายได้แค่ 10 ถ้วย และกำไรต่อถ้วยต่ำกว่าค่าเฉลี่ย',
      actionTip:
          'กลยุทธ์: 1) ตัดออกจากเมนู (Eliminate) ทันทีเพื่อลดสต็อก 2) หากจำเป็นต้องมีไว้เป็นทางเลือก ให้เปลี่ยนสูตรให้ใช้วัตถุดิบร่วมกับเมนูอื่นแทน',
    ),
    GlossaryTerm(
      id: 'yield_pct',
      title: 'Yield Percentage (อัตราผลผลิตเนื้อวัตถุดิบสุทธิ %)',
      englishName: 'Yield % / Edible Portion (EP)',
      category: 'วัตถุดิบ & ครัว',
      icon: Icons.scale_rounded,
      color: AppTheme.warning,
      oneLiner: 'ซื้อของมา 1 กิโลกรัม ตัดแต่งล้างทำความสะอาดแล้ว เหลือเนื้อเอาไปใช้จริงกี่ %',
      details:
          'สัดส่วนน้ำหนักวัตถุดิบที่ใช้ปรุงอาหารได้จริง (Edible Portion) หลังหักส่วนที่สูญเสียจากการปอกเปลือก เลาะกระดูก ลอกหนัง ตัดแต่งไขมัน หรือการหดตัวจากการละลายน้ำแข็ง',
      formula: '(น้ำหนักวัตถุดิบสุทธิที่ใช้ได้จริง ÷ น้ำหนักวัตถุดิบตอนซื้อมา) × 100',
      benchmark: 'เนื้อสัตว์แต่งพิเศษ Yield 80-90%, ผักสด Yield 70-85%, อาหารทะเลสด Yield 60-75%',
      example:
          'ซื้อปลาแซลมอนทั้งตัวมา 1,000 กรัม ราคา 450 บาท หลังขูดเกล็ด ตัดหัว แล่ก้างออก เหลือน้ำหนักเนื้อสเต็ก 700 กรัม คิดเป็น Yield = 70% ต้นทุนเนื้อจริงคือ 450 ÷ 0.70 = 642.86 บาท/กก.',
      actionTip:
          'การคิดต้นทุนด้วยราคาซื้อดิบๆ โดยไม่หาร Yield % จะทำให้คำนวณต้นทุนต่ำกว่าความเป็นจริง (Under-costing) และทำให้กำไรหายไปโดยไม่รู้ตัว!',
    ),
    GlossaryTerm(
      id: 'cost_per_base_unit',
      title: 'Cost Per Base Unit (ต้นทุนต่อหน่วยมาตรฐาน)',
      englishName: 'Cost Per Base Unit',
      category: 'วัตถุดิบ & ครัว',
      icon: Icons.calculate_rounded,
      color: AppTheme.info,
      oneLiner: 'การแปลงราคาซื้อหน่วยใหญ่ ให้เป็นหน่วยย่อยกรัม/มล. ที่ตักใส่จาน',
      details:
          'กระบวนการแปลงหน่วยจากหน่วยจัดซื้อ (Purchase Unit เช่น ลัง, ถัง, ปี๊บ, กระสอบ 25 กิโลกรัม) ไปสู่หน่วยมาตรฐานที่ใช้ในครัวจริง (Base Unit เช่น กรัม, มิลลิลิตร, ฟอง) พร้อมคิดรวมผลกระทบจาก Yield %',
      formula: '(ราคาซื้อต่อหน่วยใหญ่ ÷ ปริมาณหน่วยย่อยทั้งหมด) ÷ (Yield % ÷ 100)',
      benchmark: 'จำเป็นสำหรับการคำนวณสูตรอาหารระดับกรัมให้แม่นยำ',
      example:
          'ซื้อน้ำมันงาขวดละ 500 มล. ราคา 180 บาท (Yield 100%) ต้นทุนต่อมิลลิลิตร = 180 ÷ 500 = 0.36 บาท/มล. ถ้าสูตรใช้ 10 มล. ต้นทุนคือ 3.60 บาท',
      actionTip:
          'ตรวจสอบให้แน่ใจว่าหน่วยในสูตรสอดคล้องกับหน่วยที่ชั่งตวง เช่น ชั่งน้ำหนักเป็นกรัม ไม่ผสมปนเปกับช้อนโต๊ะที่กะเกณฑ์ไม่แน่นอน',
    ),
    GlossaryTerm(
      id: 'what_if_simulation',
      title: 'What-If Simulation (การจำลองความเสี่ยงและการเปลี่ยนแปลงต้นทุน)',
      englishName: 'What-If Cost Simulation',
      category: 'การจำลอง & จุดคุ้มทุน',
      icon: Icons.tune_rounded,
      color: AppTheme.primary,
      oneLiner: 'ทดลองหมุนตัวเลขล่วงหน้าว่า "ถ้าราคาของขึ้น ร้านเราจะกระทบกี่บาท"',
      details:
          'แบบจำลองจำลองผลกระทบทางการเงินเชิงคาดการณ์ (Predictive Scenario) เพื่อทดสอบว่าหากต้นทุนวัตถุดิบบางตัว หรือทั้งตลาดปรับตัวสูงขึ้น จะส่งผลต่อกำไรสุทธิรวมของร้านและดันเมนูไหนให้หลุดจากเกณฑ์ปลอดภัย',
      formula: 'กำไรสุทธิเดิม vs กำไรสุทธิใหม่หลังผันแปรราคาวัตถุดิบตามยอดขายจริง',
      benchmark: 'ควรจำลองสถานการณ์ความเสี่ยงเงินเฟ้อ +5%, +10% และวิกฤตวัตถุดิบคีย์หลัก +20% เสมอ',
      example:
          'ร้านจำลองว่าถ้าหมูสามชั้นขึ้นราคา +15% จะทำให้กำไรสุทธิของร้านลดลง 8,500 บาท/เดือน และเมนูข้าวหมูกรอบจะมี Food Cost พุ่งจาก 33% ไปเป็น 38%',
      actionTip:
          'เมื่อเห็นผลจำลองล่วงหน้า ผู้บริหารร้านสามารถวางแผนรับมือได้ทันท่วงที เช่น เตรียมโปรโมทเมนูไก่หรือปลาทดแทน หรือจัดแคมเปญเซ็ตเมนูก่อนที่ผลประกอบการจะเสียหายจริง',
    ),
    GlossaryTerm(
      id: 'break_even_analysis',
      title: 'Break-Even Analysis (การวิเคราะห์จุดคุ้มทุน)',
      englishName: 'Break-Even Point (BEP)',
      category: 'การจำลอง & จุดคุ้มทุน',
      icon: Icons.balance_rounded,
      color: Color(0xFF38BDF8),
      oneLiner: 'ยอดขายขั้นต่ำที่ร้านต้องขายให้ได้ในแต่ละเดือน เพื่อไม่ให้ควักเนื้อ',
      details:
          'ระดับยอดขาย (ทั้งในรูปจำนวนเงินบาท หรือจำนวนจานอาหาร) ที่ทำให้รายได้รวมเท่ากับค่าใช้จ่ายทั้งหมดของร้านพอดี (ทั้งต้นทุนคงที่ เช่น ค่าเช่า เงินเดือน และต้นทุนผันแปร เช่น ค่าอาหาร)',
      formula: 'จุดคุ้มทุน (บาท) = ต้นทุนคงที่รวม (Fixed Costs) ÷ สัดส่วนกำไรส่วนเกินเฉลี่ย (Average CM %)',
      benchmark: 'ร้านอาหารควรทำยอดขายเกินจุดคุ้มทุนให้ได้ตั้งแต่ช่วงสัปดาห์ที่ 2 หรือ 3 ของเดือน',
      example:
          'ร้านมีค่าเช่าและเงินเดือนรวม 100,000 บาท/เดือน สัดส่วนกำไรส่วนเกินเฉลี่ย 65% จุดคุ้มทุนคือ 100,000 ÷ 0.65 = 153,846 บาท/เดือน (ต้องขายให้ได้เฉลี่ยวันละ 5,128 บาทจึงจะไม่ขาดทุน)',
      actionTip:
          'การลด Food Cost % ลงเพียง 2-3% จะช่วยลดระดับยอดขายจุดคุ้มทุนลงได้อย่างมหาศาล ทำให้ร้านถึงจุดทำกำไรได้เร็วขึ้นในแต่ละเดือน',
    ),
  ];

  /// Generates full comprehensive Markdown manual for download or export.
  static String generateMarkdownGuide() {
    final buffer = StringBuffer();
    buffer.writeln('# คู่มือคำศัพท์และกลยุทธ์การบริหารต้นทุนร้านอาหาร (Restaurant Food Cost & Menu Engineering Guide)');
    buffer.writeln();
    buffer.writeln('> จัดทำโดยระบบ Food Cost & Menu Engineering Analyzer');
    buffer.writeln('> เหมาะสำหรับเจ้าของร้านอาหาร, เชฟ, ผู้จัดการฝ่ายจัดซื้อ, และทีมงานบริหารครัว');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('## สารบัญหัวข้อสำคัญ');
    buffer.writeln('1. [ทำความเข้าใจต้นทุนและกำไร (Cost & Profit Fundamentals)](#1-ทำความเข้าใจต้นทุนและกำไร)');
    buffer.writeln('2. [เมทริกซ์วิเคราะห์เมนูอาหาร 4 กลุ่ม (Kasavana & Smith Matrix)](#2-เมทริกซ์วิเคราะห์เมนูอาหาร-4-กลุ่ม)');
    buffer.writeln('3. [การจัดการวัตถุดิบและผลผลิตในครัว (Yield & Base Units)](#3-การจัดการวัตถุดิบและผลผลิตในครัว)');
    buffer.writeln('4. [การจำลองสถานการณ์ต้นทุนและจุดคุ้มทุน (Simulation & Break-Even)](#4-การจำลองสถานการณ์ต้นทุนและจุดคุ้มทุน)');
    buffer.writeln('5. [ตารางสรุปเกณฑ์มาตรฐานที่ร้านอาหารควรจำ](#5-ตารางสรุปเกณฑ์มาตรฐานที่ร้านอาหารควรจำ)');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // Group terms by category
    final categories = ['ต้นทุน & กำไร', 'เมทริกซ์ 4 กลุ่ม', 'วัตถุดิบ & ครัว', 'การจำลอง & จุดคุ้มทุน'];

    int catIndex = 1;
    for (final cat in categories) {
      buffer.writeln('## $catIndex. หมวด: $cat');
      buffer.writeln();

      final catTerms = terms.where((t) => t.category == cat).toList();
      for (final term in catTerms) {
        buffer.writeln('### 📌 ${term.title}');
        buffer.writeln('**ชื่อภาษาอังกฤษ:** `${term.englishName}`');
        buffer.writeln();
        buffer.writeln('**💡 สรุปแบบเข้าใจง่าย:** ${term.oneLiner}');
        buffer.writeln();
        buffer.writeln('**📖 คำอธิบายอย่างละเอียด:**');
        buffer.writeln(term.details);
        buffer.writeln();

        if (term.formula != null) {
          buffer.writeln('**📐 สูตรการคำนวณ:**');
          buffer.writeln('```');
          buffer.writeln(term.formula);
          buffer.writeln('```');
          buffer.writeln();
        }

        if (term.benchmark != null) {
          buffer.writeln('**🎯 เกณฑ์มาตรฐานธุรกิจ:** ${term.benchmark}');
          buffer.writeln();
        }

        buffer.writeln('**🍳 ตัวอย่างจริงในร้านอาหาร:**');
        buffer.writeln('> ${term.example}');
        buffer.writeln();

        buffer.writeln('**🚀 ข้อแนะนำเชิงกลยุทธ์ (Action Tip):**');
        buffer.writeln('> ${term.actionTip}');
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
      }
      catIndex++;
    }

    buffer.writeln('## 5. ตารางสรุปเกณฑ์มาตรฐานที่ร้านอาหารควรจำ');
    buffer.writeln();
    buffer.writeln('| ตัวชี้วัด / กลุ่ม | สัญลักษณ์ | เกณฑ์มาตรฐาน | ความหมายเชิงธุรกิจ | สิ่งที่ควรทำทันที |');
    buffer.writeln('| :--- | :---: | :---: | :--- | :--- |');
    buffer.writeln('| **Food Cost % (ดีเยี่ยม)** | 🟢 | ต่ำกว่า 28% | ต้นทุนต่ำมาก ทำกำไรได้สูง | รักษามาตรฐานสูตร |');
    buffer.writeln('| **Food Cost % (ปกติ)** | 🟡 | 28% - 35% | เกณฑ์มาตรฐานร้านอาหารส่วนใหญ่ | คุมของเสียและ Portion |');
    buffer.writeln('| **Food Cost % (อันตราย)** | 🔴 | มากกว่า 35% | กำไรบาง เสี่ยงขาดทุน | ปรับราคา / ปรับสูตรด่วน |');
    buffer.writeln('| **Stars (ดาวเด่น)** | ⭐ | ขายดี + กำไรสูง | เมนูพระเอก นำเงินเข้ากระเป๋า | วางจุดเด่นในเล่มเมนู ห้ามลดคุณภาพ |');
    buffer.writeln('| **Plowhorses (ม้าศึก)** | 🐎 | ขายดี + กำไรต่ำ | ขวัญใจมหาชนแต่เหนื่อยเปล่า | ขยับราคาทีละนิด หรือทำ Combo Set |');
    buffer.writeln('| **Puzzles (ปริศนา)** | 🧩 | ขายน้อย + กำไรสูง | ของดีกำไรปังแต่ไม่มีใครรู้ | ถ่ายรูปใหม่ เปลี่ยนชื่อ ให้เด็กเสิร์ฟเชียร์ |');
    buffer.writeln('| **Dogs (สุนัขจนตรอก)** | 🐶 | ขายน้อย + กำไรต่ำ | เปลืองสต็อก เพิ่มภาระครัว | ตัดทิ้งจากเล่มเมนู หรือดัดแปลงสูตร |');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln('เอกสารนี้ถูกสร้างโดย Food Cost Analyzer เพื่อส่งเสริมการบริหารร้านอาหารอย่างยั่งยืน');

    return buffer.toString();
  }
}

/// Interactive Dialog to view and search business glossary terms + download manual.
class BusinessGlossaryDialog extends StatefulWidget {
  const BusinessGlossaryDialog({super.key});

  @override
  State<BusinessGlossaryDialog> createState() => _BusinessGlossaryDialogState();
}

class _BusinessGlossaryDialogState extends State<BusinessGlossaryDialog> {
  String _searchQuery = '';
  String _selectedCategory = 'ทั้งหมด';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'ทั้งหมด',
    'ต้นทุน & กำไร',
    'เมทริกซ์ 4 กลุ่ม',
    'วัตถุดิบ & ครัว',
    'การจำลอง & จุดคุ้มทุน',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _downloadGuide() {
    final markdownContent = BusinessGlossary.generateMarkdownGuide();
    downloadFileFromString(
      markdownContent,
      'คู่มือคำศัพท์และกลยุทธ์ต้นทุนร้านอาหาร_FoodCost_Guide.md',
      'text/markdown;charset=utf-8',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: AppTheme.primaryNeon, size: 20),
              SizedBox(width: 10),
              Text('ดาวน์โหลดคู่มือคำศัพท์ธุรกิจเรียบร้อยแล้ว (FoodCost_Guide.md)'),
            ],
          ),
          backgroundColor: AppTheme.surfaceMuted,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = (screenSize.width - 48).clamp(320.0, 920.0);
    final dialogHeight = (screenSize.height - 64).clamp(480.0, 780.0);

    // Filter terms
    final filteredTerms = BusinessGlossary.terms.where((term) {
      final matchesCategory = _selectedCategory == 'ทั้งหมด' || term.category == _selectedCategory;
      final q = _searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          term.title.toLowerCase().contains(q) ||
          term.englishName.toLowerCase().contains(q) ||
          term.oneLiner.toLowerCase().contains(q) ||
          term.details.toLowerCase().contains(q) ||
          term.example.toLowerCase().contains(q);
      return matchesCategory && matchesSearch;
    }).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Deep modern navy
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 32,
              spreadRadius: 8,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            const Divider(height: 1, color: AppTheme.border),

            // Search Bar & Categories
            _buildSearchAndFilters(),
            const Divider(height: 1, color: AppTheme.border),

            // Content List
            Expanded(
              child: filteredTerms.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredTerms.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _buildTermCard(filteredTerms[index]);
                      },
                    ),
            ),

            // Footer with download banner
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryNeon],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'คู่มือคำศัพท์ธุรกิจ & เมทริกซ์เมนูอาหาร',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Restaurant Financial & Menu Engineering Business Glossary',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _downloadGuide,
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('ดาวน์โหลดคู่มือ (.md)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
            tooltip: 'ปิดหน้าต่าง',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: Colors.white.withValues(alpha: 0.015),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search TextField
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(fontSize: 13, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'ค้นหาคำศัพท์ (เช่น Food Cost, Stars, Margin, Yield, จุดคุ้มทุน)...',
              hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.textMuted),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16, color: AppTheme.textMuted),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.04),
                    selectedColor: AppTheme.primary.withValues(alpha: 0.8),
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppTheme.primary : AppTheme.border,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermCard(GlossaryTerm term) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Accent Line
            Container(
              height: 3,
              color: term.color,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: term.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(term.icon, size: 20, color: term.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              term.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              term.englishName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: term.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(
                          term.category,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // One-liner banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: term.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: term.color.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_rounded, size: 16, color: term.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            term.oneLiner,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Detailed explanation
                  Text(
                    term.details,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),

                  // Formula & Benchmark
                  if (term.formula != null || term.benchmark != null) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        if (term.formula != null)
                          Container(
                            constraints: const BoxConstraints(maxWidth: 600),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF090D16),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.functions_rounded, size: 14, color: AppTheme.primaryNeon),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'สูตร: ${term.formula}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryNeon,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (term.benchmark != null)
                          Container(
                            constraints: const BoxConstraints(maxWidth: 600),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.info.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.info.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppTheme.info),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    term.benchmark!,
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFFBAE6FD)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Real-world Restaurant Example
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.restaurant_rounded, size: 16, color: AppTheme.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ตัวอย่างจริงในร้านอาหาร:',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.warning,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                term.example,
                                style: const TextStyle(fontSize: 12, height: 1.4, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Strategy Action Tip
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.18)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.bolt_rounded, size: 16, color: AppTheme.primaryNeon),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ข้อแนะนำเชิงกลยุทธ์ (Action Tip):',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryNeon,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                term.actionTip,
                                style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            'ไม่พบคำศัพท์ที่ตรงกับ "$_searchQuery"',
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          const Text(
            'ลองค้นหาด้วยคำว่า: Food Cost, Star, Margin, Yield, จุดคุ้มทุน',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundElevated,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_stories_rounded, size: 16, color: AppTheme.primaryNeon),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'คู่มือนี้อ้างอิงหลักการ Menu Engineering ของ Kasavana & Smith และมาตรฐานการจัดการต้นทุนครัวสากล',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _downloadGuide,
            icon: const Icon(Icons.download_rounded, size: 14),
            label: const Text('ดาวน์โหลดคู่มือฉบับเต็ม'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryNeon,
              side: const BorderSide(color: AppTheme.primaryNeon),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper method to open the Business Glossary Dialog from anywhere in the app.
void showBusinessGlossaryDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const BusinessGlossaryDialog(),
  );
}
