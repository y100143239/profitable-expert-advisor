//+------------------------------------------------------------------+
//|                                         BrokerSymbolMapper.mqh   |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property strict

/*
   This class maps "Base" symbols to "Broker-Specific" symbols.
   It helps adapt the EA to different brokers like IC Markets, MetaQuotes, Pepperstone, etc.
*/

class CBrokerSymbolMapper
{
private:
    string m_broker;

public:
    CBrokerSymbolMapper()
    {
        m_broker = AccountInfoString(ACCOUNT_COMPANY);
    }

    string GetTerminalSymbol(string baseSymbol)
    {
        // --- 0. Exact Match Priority ---
        // If the provided symbol already exists in the terminal, use it directly.
        // This allows for manual overrides and custom backtest symbols (e.g. _Duka).
        if(baseSymbol != "" && SymbolSelect(baseSymbol, true)) return baseSymbol;

        // --- 1. Clean the base symbol ---
        // Remove common suffixes to get the "Clean" core name (e.g. AAPL.NAS -> AAPL)
        string clean = baseSymbol;
        string suffixes[] = {".NAS", ".US", ".m", ".c", ".i", "!", "+", "_Duka"};
        for(int i=0; i<ArraySize(suffixes); i++)
        {
            int pos = StringFind(clean, suffixes[i]);
            if(pos > 0) 
            {
               clean = StringSubstr(clean, 0, pos);
               break; 
            }
        }
        
        string result = clean;
        
        // --- MetaQuotes Logic ---
        if(StringFind(m_broker, "MetaQuotes") >= 0)
        {
            if(clean == "BTCUSD") return ""; // BTC:无代码
            if(clean == "GER40")  result = "DE40";
        }
        
        // --- IC Markets Logic ---
        else if(StringFind(m_broker, "IC Markets") >= 0 || StringFind(m_broker, "Raw Trading") >= 0)
        {
            if(clean == "GER40")  result = "DE40";
            if(clean == "AAPL")   result = "AAPL.NAS";
            if(clean == "NVDA")   result = "NVDA.NAS";
            if(clean == "TSLA")   result = "TSLA.NAS";
        }
        
        // --- TradeMax Logic ---
        else if(StringFind(m_broker, "TradeMax") >= 0)
        {
            if(clean == "AAPL")   result = "AAPL.NAS";
            if(clean == "NVDA")   result = "NVDA.NAS";
            if(clean == "TSLA")   result = "TSLA.NAS";
            if(clean == "GER40")  result = "GER40";
        }

        // --- Pepperstone Logic ---
        else if(StringFind(m_broker, "Pepperstone") >= 0)
        {
            if(clean == "AAPL")   result = "AAPL.US";
            if(clean == "NVDA")   result = "NVDA.US";
            if(clean == "TSLA")   result = "TSLA.US";
            if(clean == "GER40")  result = "GER40";
        }


        // --- Generic Fallback & Suffix Handling ---
        // 1. Check if the mapped result exists and can be selected
        if(result != "" && SymbolSelect(result, true)) return result;
        
        // 2. Check if the original baseSymbol exists
        if(baseSymbol != "" && SymbolSelect(baseSymbol, true)) return baseSymbol;
        
        // 3. Try common suffixes on the baseSymbol
        string variations[] = {baseSymbol + ".m", baseSymbol + "+", baseSymbol + "c", baseSymbol + "!", baseSymbol + ".NAS", baseSymbol + ".US"};
        for(int i=0; i<ArraySize(variations); i++)
        {
            if(SymbolSelect(variations[i], true)) return variations[i];
        }

        // 4. Final Search: Try to find by substring if not found
        for(int i=0; i<SymbolsTotal(false); i++)
        {
            string sym = SymbolName(i, false);
            if(StringFind(sym, baseSymbol) >= 0)
            {
                 // Only return the symbol if it can actually be selected
                 if(SymbolSelect(sym, true))
                     return sym;
            }
        }

        return result;
    }
};

// Global Instance
CBrokerSymbolMapper SymbolMapper;
