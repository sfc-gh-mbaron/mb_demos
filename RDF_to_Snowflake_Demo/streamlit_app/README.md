# RDF Semantic Chat Assistant - Streamlit App

## Overview

This Streamlit application provides a conversational interface for querying RDF-derived semantic data using Snowflake's Cortex Analyst and native Semantic Views. Users can ask natural language questions and get instant insights from their data.

![App Preview](../images/streamlit_app_preview.png)

## Features

### 🤖 **Natural Language Querying**
- Chat interface powered by Cortex Analyst
- Pre-built sample questions to get started
- Intelligent query routing to appropriate semantic views

### 📊 **Interactive Semantic Views**
- Explore available dimensions and metrics
- Build custom queries using drag-and-drop interface  
- Real-time semantic SQL generation

### 📈 **Visualizations**
- Auto-generated charts from query results
- Multiple chart types (bar, line, scatter)
- Summary statistics and KPI cards

### 🎯 **Semantic Intelligence**
- Browse semantic view structure
- Understand business metrics and dimensions
- See generated SQL for transparency

## Prerequisites

1. **Snowflake Account** with:
   - Cortex Analyst enabled
   - Semantic Views feature available
   - Appropriate privileges for the user

2. **Demo Setup Complete**:
   - RDF to Snowflake semantic views deployed
   - Sample data loaded
   - All semantic views created

3. **Python Environment**:
   - Python 3.8+
   - Streamlit
   - Snowflake connectors

## Installation

### Option 1: Streamlit in Snowflake (Recommended)

1. **Upload to Snowflake Stage:**
   ```sql
   PUT file://./cortex_analyst_chat.py @~;
   ```

2. **Create Streamlit App:**
   ```sql
   CREATE STREAMLIT RDF_SEMANTIC_CHAT
   ROOT_LOCATION = '@~/cortex_analyst_chat.py'
   MAIN_FILE = 'cortex_analyst_chat.py'
   QUERY_WAREHOUSE = 'RDF_DEMO_WH';
   ```

3. **Access the App:**
   - Navigate to your Snowflake account
   - Go to Streamlit section
   - Click on "RDF_SEMANTIC_CHAT"

### Option 2: Local Development

1. **Install Dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure Snowflake Connection:**
   Create `~/.snowflake/connections.toml`:
   ```toml
   [default]
   account = "your-account-identifier"
   user = "your-username"
   password = "your-password"
   role = "SYSADMIN"
   warehouse = "RDF_DEMO_WH"
   database = "RDF_SEMANTIC_DB"
   schema = "SEMANTIC_VIEWS"
   ```

3. **Run the App:**
   ```bash
   streamlit run cortex_analyst_chat.py
   ```

## Usage Guide

### Getting Started

1. **Select Semantic View**: Choose from available semantic views in the sidebar
2. **Explore Structure**: Review available dimensions and metrics
3. **Ask Questions**: Use natural language or the query builder
4. **View Results**: See data tables and auto-generated visualizations

### Sample Questions

Try these natural language queries:

- **Revenue Analysis**: "What is our total revenue?"
- **Customer Insights**: "Show me the top customers by value"
- **Product Performance**: "Which products are selling best?"
- **Trend Analysis**: "Show me recent sales trends"
- **Category Analysis**: "Which categories generate the most revenue?"

### Query Builder

For more control, use the sidebar query builder:

1. Select dimensions (categorical data)
2. Choose metrics (quantitative measures)
3. Set result limits
4. Click "Run Query"

### Visualizations

The app automatically creates charts based on your data:

- **Bar Charts**: For categorical comparisons
- **Line Charts**: For trends over time
- **Scatter Plots**: For correlations between metrics

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Streamlit UI  │────│  Cortex Analyst  │────│ Semantic Views  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                        │
         │              ┌────────▼────────┐              │
         │              │  Natural Lang   │              │
         └──────────────│  → Semantic SQL │──────────────┘
                        └─────────────────┘
```

### Key Components

1. **Frontend**: Streamlit web interface
2. **AI Layer**: Cortex Analyst for natural language processing
3. **Semantic Layer**: Snowflake Semantic Views with business logic
4. **Data Layer**: Physical tables from RDF conversion

## Customization

### Adding New Questions

Modify the `simulate_cortex_analyst_query()` function to handle new question patterns:

```python
elif "your_pattern" in question_lower:
    dimensions = ["YOUR_DIMENSION"]
    metrics = ["YOUR_METRIC"]
    filters = "your_filter"
```

### Custom Visualizations

Extend the `create_visualization()` function for new chart types:

```python
elif chart_type == "your_chart":
    fig = px.your_chart_type(df, ...)
```

### Styling

Modify the CSS in the `st.markdown()` section for custom themes.

## Troubleshooting

### Common Issues

1. **"No semantic views found"**
   - Ensure demo setup scripts have been run
   - Check database/schema context
   - Verify user privileges

2. **Connection errors**
   - Validate Snowflake credentials
   - Check network connectivity
   - Ensure warehouse is running

3. **Query failures**
   - Review semantic view structure
   - Check dimension/metric names
   - Validate filters

### Debug Mode

Enable debug logging:

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

## Performance Tips

1. **Limit Result Sets**: Use reasonable limits for large datasets
2. **Cache Queries**: Leverage Streamlit's caching for repeated queries
3. **Optimize Views**: Ensure semantic views are well-designed
4. **Warehouse Sizing**: Use appropriate warehouse size for workload

## Security Considerations

1. **Role-Based Access**: Use appropriate Snowflake roles
2. **Data Privacy**: Semantic views can control data access
3. **Connection Security**: Use secure connection methods
4. **Parameter Validation**: The app validates all inputs

## Support

For issues or questions:

1. Check the [main demo documentation](../README.md)
2. Review Snowflake's [Cortex Analyst documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst)
3. Consult [Semantic Views documentation](https://docs.snowflake.com/en/user-guide/views-semantic)

## Contributing

To contribute improvements:

1. Fork the repository
2. Create a feature branch
3. Test with the demo data
4. Submit a pull request

---

**Built with ❤️ using Snowflake's Semantic Views and Cortex Analyst**