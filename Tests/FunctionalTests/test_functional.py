#!/usr/bin/env python3
"""
PortfolioX 功能测试脚本
测试核心功能：格式化、API 响应解析、盈亏计算
"""

import json
import unittest
from datetime import datetime


# ============================================================
# 模拟 Swift Formatters 逻辑
# ============================================================

def format_cny(value: float) -> str:
    """模拟 Formatters.formatCNY()"""
    sign = "-" if value < 0 else ""
    abs_val = abs(value)
    # 模拟 NumberFormatter(.currency, currencyCode="CNY", symbol="¥")
    formatted = f"¥{abs_val:,.2f}"
    return f"{sign}{formatted}"


def format_percent(value: float) -> str:
    """模拟 Formatters.formatPercent()"""
    sign = "+" if value >= 0 else ""
    return f"{sign}{value:.2f}%"


def format_price(value: float) -> str:
    """模拟 Formatters.formatPrice()"""
    return f"{value:,.2f}"


def format_change(value: float) -> str:
    """模拟 Formatters.formatChange()"""
    sign = "+" if value >= 0 else ""
    return f"{sign}{value:,.2f}"


# ============================================================
# 模拟 Tencent API 响应解析
# ============================================================

def parse_tencent_response(text: str, symbols: list[str], market: str) -> dict:
    """
    模拟 fetchTencentQuotes 的解析逻辑
    market: "us" 或 "hk"
    """
    prefix = "us" if market == "us" else "hk"
    var_prefix = "v_us" if market == "us" else "v_hk"

    # HK 股票需要用 5 位代码（如 "00700" 而非 "0700"）
    api_symbols = []
    symbol_map = {}
    for sym in symbols:
        if market == "hk" and sym.isdigit():
            api_sym = f"{int(sym):05d}"
        else:
            api_sym = sym
        api_symbols.append(api_sym)
        symbol_map[api_sym] = sym

    quotes = {}

    for line in text.strip().split("\n"):
        line = line.strip()
        if not line.startswith("v_"):
            continue

        # 提取引号内的值
        quote_start = line.find("\"")
        quote_end = line.rfind("\"")
        if quote_start == -1 or quote_end == -1:
            continue
        value = line[quote_start + 1:quote_end]
        parts = value.split("~")

        if len(parts) < 36:
            continue

        try:
            price = float(parts[3])
            prev_close = float(parts[4])
        except (ValueError, IndexError):
            continue

        change = price - prev_close
        change_percent = (change / prev_close * 100) if prev_close > 0 else 0

        # 从变量名提取符号: v_hk00700="..." → "00700" → 映射回 "0700"
        eq_pos = line.find("=")
        var_name = line[:eq_pos] if eq_pos > 0 else ""
        api_sym = var_name[len(var_prefix):] if var_name.startswith(var_prefix) else ""
        symbol = symbol_map.get(api_sym, api_sym)

        quotes[symbol] = {
            "symbol": symbol,
            "price": price,
            "change": change,
            "changePercent": change_percent,
            "currency": "USD" if market == "us" else "HKD",
        }

    return quotes


# ============================================================
# 模拟 Sina API 响应解析
# ============================================================

def parse_sina_response(text: str) -> dict:
    """
    模拟 parseSinaResponse 的解析逻辑
    """
    quotes = {}

    for line in text.strip().split("\n"):
        line = line.strip()
        if not line or "hq_str_" not in line:
            continue

        parts_by_quote = line.split("\"")
        if len(parts_by_quote) < 2:
            continue

        value_str = parts_by_quote[1]
        fields = value_str.split(",")
        if len(fields) < 32:
            continue

        try:
            price = float(fields[3])
            prev_close = float(fields[2])
        except (ValueError, IndexError):
            price = 0
            prev_close = price if price > 0 else 0

        change = price - prev_close
        change_percent = (change / prev_close * 100) if prev_close > 0 else 0

        # 提取符号: var hq_str_sh600519="..." → "600519"
        var_part = parts_by_quote[0]
        raw = var_part.replace("var hq_str_", "").replace(";", "").strip("=")
        symbol = raw[2:]  # drop "sh"/"sz"

        quotes[symbol] = {
            "symbol": symbol,
            "price": price,
            "change": change,
            "changePercent": change_percent,
            "currency": "CNY",
        }

    return quotes


# ============================================================
# 模拟 Portfolio P&L 计算
# ============================================================

def calc_pnl(price: float, change: float, shares: float, avg_cost: float | None,
             rate: float = 1.0) -> dict:
    """模拟 StockPnL 的盈亏计算"""
    market_value_cny = price * shares * rate
    day_pnl_cny = change * shares * rate
    unrealized_pnl_cny = (price - avg_cost) * shares * rate if avg_cost and avg_cost > 0 else 0

    return {
        "marketValueCNY": market_value_cny,
        "dayPnLCNY": day_pnl_cny,
        "unrealizedPnLCNY": unrealized_pnl_cny,
    }


# ============================================================
# 测试用例
# ============================================================

class TestFormatters(unittest.TestCase):
    """格式化器功能测试"""

    def test_format_cny_positive(self):
        self.assertEqual(format_cny(1234.56), "¥1,234.56")

    def test_format_cny_negative(self):
        """负数应显示 -¥ 前缀，而非括号"""
        self.assertEqual(format_cny(-1234.56), "-¥1,234.56")

    def test_format_cny_zero(self):
        self.assertEqual(format_cny(0), "¥0.00")

    def test_format_cny_large(self):
        self.assertEqual(format_cny(-12345678.90), "-¥12,345,678.90")

    def test_format_cny_small(self):
        """验证 1 元以下金额"""
        self.assertEqual(format_cny(0.50), "¥0.50")

    def test_format_percent_positive(self):
        self.assertEqual(format_percent(1.23), "+1.23%")

    def test_format_percent_negative(self):
        self.assertEqual(format_percent(-0.83), "-0.83%")

    def test_format_percent_zero(self):
        self.assertEqual(format_percent(0), "+0.00%")

    def test_format_price(self):
        self.assertEqual(format_price(276.83), "276.83")

    def test_format_price_large(self):
        self.assertEqual(format_price(471.200), "471.20")

    def test_format_change_positive(self):
        self.assertEqual(format_change(3.31), "+3.31")

    def test_format_change_negative(self):
        self.assertEqual(format_change(-1.80), "-1.80")

    def test_format_change_zero(self):
        self.assertEqual(format_change(0), "+0.00")


class TestTencentParsing(unittest.TestCase):
    """腾讯行情 API 解析测试"""

    TENCENT_US_RESPONSE = '''v_usAAPL="200~Apple~AAPL.OQ~276.83~280.14~279.66~46668401~0~0~276.50~80~0~0~0~0~0~0~0~0~276.53~200~0~0~0~0~0~0~0~0~~2026-05-04 16:00:02~-3.31~-1.18~280.63~274.86~USD~46668401~12923138919~0.32~33.51~~37.11~~2.06~40579.44910~40604.56069~Apple Inc.~8.26~288.36~192.42~-120~38.13~0.38~40604.56069~1.92~3.45~GP~141.47~34.91~1.38~6.94~0.42~14667688000~14658616878~0.82~28.54~1.04~276.91~~~";
'''

    TENCENT_HK_RESPONSE = '''v_hk00700="100~Tencent~00700~471.200~473.000~469.000~11414723.0~0~0~471.200~0~0~0~0~0~0~0~0~0~471.200~0~0~0~0~0~0~0~0~0~11414723.0~2026/05/05 15:46:09~-1.800~-0.38~472.400~465.600~471.200~11414723.0~5354933218.720~0~17.27~~0~0~1.44~42999.8161~42999.8161~TENCENT~0.96~683.000~463.200~0.39~-3.08~0~0~0~0~0~17.27~3.39~0.13~100~-21.34~-1.55~GP~19.48~11.27~-9.82~-5.11~-22.24~9125597636.00~9125597636.00~17.27~4.531~469.125~-16.90~HKD~1~30";
'''

    TENCENT_MULTI_RESPONSE = '''v_usAAPL="200~Apple~AAPL.OQ~276.83~280.14~279.66~46668401~0~0~276.50~80~0~0~0~0~0~0~0~0~276.53~200~0~0~0~0~0~0~0~0~~2026-05-04 16:00:02~-3.31~-1.18~280.63~274.86~USD~46668401~12923138919~0.32~33.51~~37.11~~2.06~40579.44910~40604.56069~Apple Inc.~8.26~288.36~192.42~-120~38.13~0.38~40604.56069~1.92~3.45~GP~141.47~34.91~1.38~6.94~0.42~14667688000~14658616878~0.82~28.54~1.04~276.91~~~";
v_usMSFT="200~Microsoft~MSFT.OQ~413.62~414.44~411.54~28066528~0~0~412.66~80~0~0~0~0~0~0~0~0~412.83~200~0~0~0~0~0~0~0~0~~2026-05-04 16:00:02~-0.82~-0.20~420.78~410.80~USD~28066528~11651669370~0.38~24.63~~30.32~~2.41~30716.06266~30725.49162~Microsoft Corporation~16.79~552.23~356.28~-120~7.42~0.86~30725.49162~-14.28~-2.64~GP~34.01~19.93~-1.06~10.93~5.31~7428434704~7426155084~0.70~23.61~3.56~415.14~~~";
'''

    def test_parse_us_single(self):
        """解析单个美股"""
        quotes = parse_tencent_response(self.TENCENT_US_RESPONSE, ["AAPL"], "us")
        self.assertIn("AAPL", quotes)
        aapl = quotes["AAPL"]
        self.assertAlmostEqual(aapl["price"], 276.83)
        self.assertAlmostEqual(aapl["change"], -3.31)
        self.assertAlmostEqual(aapl["changePercent"], -1.18, places=2)
        self.assertEqual(aapl["currency"], "USD")

    def test_parse_hk_single(self):
        """解析单个港股"""
        quotes = parse_tencent_response(self.TENCENT_HK_RESPONSE, ["0700"], "hk")
        self.assertIn("0700", quotes)
        tencent = quotes["0700"]
        self.assertAlmostEqual(tencent["price"], 471.200)
        self.assertAlmostEqual(tencent["change"], -1.800)
        self.assertAlmostEqual(tencent["changePercent"], -0.38, places=2)
        self.assertEqual(tencent["currency"], "HKD")

    def test_parse_multiple_us(self):
        """解析多个美股"""
        quotes = parse_tencent_response(
            self.TENCENT_MULTI_RESPONSE, ["AAPL", "MSFT"], "us"
        )
        self.assertIn("AAPL", quotes)
        self.assertIn("MSFT", quotes)
        self.assertAlmostEqual(quotes["MSFT"]["price"], 413.62)

    def test_parse_negative_change(self):
        """验证下跌股票 change 为负数"""
        quotes = parse_tencent_response(self.TENCENT_US_RESPONSE, ["AAPL"], "us")
        self.assertLess(quotes["AAPL"]["change"], 0)
        self.assertLess(quotes["AAPL"]["changePercent"], 0)

    def test_parse_empty_response(self):
        """空响应应返回空字典"""
        quotes = parse_tencent_response("", [], "us")
        self.assertEqual(quotes, {})


class TestSinaParsing(unittest.TestCase):
    """新浪 A 股 API 解析测试"""

    SINA_RESPONSE = '''var hq_str_sh600519="茅台,1400.000,1401.170,1384.790,1401.170,1380.000,1384.790,1384.800,5275267,7316111748.000,168,1384.790,1100,1384.780,100,1384.760,100,1384.750,100,1384.710,900,1384.800,100,1384.820,100,1384.830,100,1384.840,1500,1384.850,2026-04-30,15:00:00,00,";
var hq_str_sz000001="平安银行,11.500,11.520,11.490,11.600,11.460,11.480,11.490,113924162,1312827775.760,97900,11.480,274093,11.470,836100,11.460,513600,11.450,166100,11.440,867383,11.490,1073000,11.500,449500,11.510,971669,11.520,478600,11.530,2026-04-30,15:00:00,00";
'''

    def test_parse_a_share(self):
        """解析 A 股"""
        quotes = parse_sina_response(self.SINA_RESPONSE)
        self.assertIn("600519", quotes)
        maotai = quotes["600519"]
        self.assertAlmostEqual(maotai["price"], 1384.790)
        self.assertAlmostEqual(maotai["change"], 1384.79 - 1401.17)
        self.assertEqual(maotai["currency"], "CNY")

    def test_parse_shenzhen(self):
        """解析深证股票"""
        quotes = parse_sina_response(self.SINA_RESPONSE)
        self.assertIn("000001", quotes)
        pingan = quotes["000001"]
        self.assertAlmostEqual(pingan["price"], 11.490)

    def test_parse_multiple_a(self):
        """解析多个 A 股"""
        quotes = parse_sina_response(self.SINA_RESPONSE)
        self.assertEqual(len(quotes), 2)
        self.assertIn("600519", quotes)
        self.assertIn("000001", quotes)


class TestPnLCalc(unittest.TestCase):
    """盈亏计算测试"""

    def test_positive_pnl(self):
        """验证盈利计算"""
        result = calc_pnl(price=150.0, change=5.0, shares=100,
                          avg_cost=140.0, rate=1.0)
        self.assertAlmostEqual(result["marketValueCNY"], 15000.0)
        self.assertAlmostEqual(result["dayPnLCNY"], 500.0)
        self.assertAlmostEqual(result["unrealizedPnLCNY"], 1000.0)

    def test_negative_pnl(self):
        """验证亏损计算"""
        result = calc_pnl(price=130.0, change=-5.0, shares=100,
                          avg_cost=140.0, rate=1.0)
        self.assertAlmostEqual(result["marketValueCNY"], 13000.0)
        self.assertAlmostEqual(result["dayPnLCNY"], -500.0)
        self.assertAlmostEqual(result["unrealizedPnLCNY"], -1000.0)

    def test_no_avg_cost(self):
        """无买入均价时浮盈应为 0"""
        result = calc_pnl(price=150.0, change=5.0, shares=100,
                          avg_cost=None, rate=1.0)
        self.assertAlmostEqual(result["marketValueCNY"], 15000.0)
        self.assertAlmostEqual(result["dayPnLCNY"], 500.0)
        self.assertAlmostEqual(result["unrealizedPnLCNY"], 0.0)

    def test_with_exchange_rate(self):
        """验证汇率转换后的盈亏"""
        result = calc_pnl(price=150.0, change=5.0, shares=100,
                          avg_cost=140.0, rate=7.2)
        self.assertAlmostEqual(result["marketValueCNY"], 108000.0)
        self.assertAlmostEqual(result["dayPnLCNY"], 3600.0)
        self.assertAlmostEqual(result["unrealizedPnLCNY"], 7200.0)

    def test_hk_three_decimal(self):
        """港股 3 位小数的精度"""
        result = calc_pnl(price=471.200, change=-1.800, shares=200,
                          avg_cost=473.000, rate=0.92)
        self.assertAlmostEqual(result["marketValueCNY"], 471.200 * 200 * 0.92)
        self.assertAlmostEqual(result["dayPnLCNY"], -1.800 * 200 * 0.92)
        self.assertAlmostEqual(result["unrealizedPnLCNY"],
                               (471.200 - 473.000) * 200 * 0.92)


class TestEndToEnd(unittest.TestCase):
    """端到端测试：解析 API 响应 → 格式化输出 → 盈亏计算"""

    TENCENT_RESPONSE = '''v_usAAPL="200~Apple~AAPL.OQ~276.83~280.14~279.66~46668401~0~0~276.50~80~0~0~0~0~0~0~0~0~276.53~200~0~0~0~0~0~0~0~0~~2026-05-04 16:00:02~-3.31~-1.18~280.63~274.86~USD~46668401~12923138919~0.32~33.51~~37.11~~2.06~40579.44910~40604.56069~Apple Inc.~8.26~288.36~192.42~-120~38.13~0.38~40604.56069~1.92~3.45~GP~141.47~34.91~1.38~6.94~0.42~14667688000~14658616878~0.82~28.54~1.04~276.91~~~";
'''

    def test_full_flow(self):
        """完整流程：解析 → 格式化 → 计算"""
        quotes = parse_tencent_response(self.TENCENT_RESPONSE, ["AAPL"], "us")
        self.assertIn("AAPL", quotes)

        aapl = quotes["AAPL"]

        # 格式化输出
        price_str = format_price(aapl["price"])
        self.assertEqual(price_str, "276.83")

        change_str = format_change(aapl["change"])
        self.assertEqual(change_str, "-3.31")

        percent_str = format_percent(aapl["changePercent"])
        self.assertEqual(percent_str, "-1.18%")

        # 盈亏计算 (假设 200 股)
        result = calc_pnl(
            price=aapl["price"],
            change=aapl["change"],
            shares=200,
            avg_cost=280.14,
            rate=7.2
        )

        expected_market = 276.83 * 200 * 7.2
        expected_day = -3.31 * 200 * 7.2
        expected_unrealized = (276.83 - 280.14) * 200 * 7.2

        self.assertAlmostEqual(result["marketValueCNY"], expected_market)
        self.assertAlmostEqual(result["dayPnLCNY"], expected_day)
        self.assertAlmostEqual(result["unrealizedPnLCNY"], expected_unrealized)

        # 格式化 CNY
        day_pnl_str = format_cny(result["dayPnLCNY"])
        self.assertTrue(day_pnl_str.startswith("-"))
        self.assertIn("¥", day_pnl_str)

        unrealized_str = format_cny(result["unrealizedPnLCNY"])
        self.assertTrue(unrealized_str.startswith("-"))
        self.assertIn("¥", unrealized_str)


if __name__ == "__main__":
    print("=" * 60)
    print("PortfolioX 功能测试")
    print(f"运行时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)
    print()

    suite = unittest.TestSuite()
    loader = unittest.TestLoader()

    # 按顺序添加测试
    suite.addTests(loader.loadTestsFromTestCase(TestFormatters))
    suite.addTests(loader.loadTestsFromTestCase(TestTencentParsing))
    suite.addTests(loader.loadTestsFromTestCase(TestSinaParsing))
    suite.addTests(loader.loadTestsFromTestCase(TestPnLCalc))
    suite.addTests(loader.loadTestsFromTestCase(TestEndToEnd))

    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)

    print()
    print("=" * 60)
    print(f"总计: {result.testsRun} 测试")
    if result.wasSuccessful():
        print("结果: ✅ 全部通过")
    else:
        print(f"结果: ❌ {len(result.failures)} 失败, {len(result.errors)} 错误")
    print("=" * 60)

    exit(0 if result.wasSuccessful() else 1)
