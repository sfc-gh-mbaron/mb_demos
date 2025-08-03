"""
Streamlit App: RDF to Snowflake Semantic Views with Cortex Analyst
This app provides a chat interface for natural language queries using Cortex Analyst
and the semantic views created from RDF schemas.
"""

import streamlit as st
import snowflake.connector
import json
import pandas as pd
from datetime import datetime
import plotly.express as px
import plotly.graph_objects as go
from snowflake.snowpark.context import get_active_session

# Configure Streamlit page
st.set_page_config(
    page_title="RDF Semantic Chat Assistant",
    page_icon="🤖",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS for better styling
st.markdown("""
<style>
    .main-header {
        font-size: 2.5rem;
        font-weight: bold;
        color: #1f77b4;
        text-align: center;
        margin-bottom: 2rem;
    }
    .chat-message {
        padding: 1rem;
        border-radius: 0.5rem;
        margin: 0.5rem 0;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .user-message {
        background-color: #e3f2fd;
        border-left: 4px solid #2196f3;
    }
    .assistant-message {
        background-color: #f1f8e9;
        border-left: 4px solid #4caf50;
    }
    .semantic-info {
        background-color: #fff3e0;
        border: 1px solid #ff9800;
        border-radius: 0.5rem;
        padding: 1rem;
        margin: 1rem 0;
    }
    .metric-card {
        background-color: #fafafa;
        border-radius: 0.5rem;
        padding: 1rem;
        text-align: center;
        border: 1px solid #e0e0e0;
    }
</style>
""", unsafe_allow_html=True)

def initialize_session():
    """Initialize Snowflake session and check semantic views"""
    try:
        # Get active Snowflake session
        session = get_active_session()
        
        # Set context
        session.sql("USE DATABASE RDF_SEMANTIC_DB").collect()
        session.sql("USE SCHEMA SEMANTIC_VIEWS").collect()
        
        return session
    except Exception as e:
        st.error(f"Failed to connect to Snowflake: {str(e)}")
        return None

def get_semantic_views(session):
    """Get available semantic views"""
    try:
        result = session.sql("SHOW SEMANTIC VIEWS").collect()
        return [row[1] for row in result]  # View names are in second column
    except Exception as e:
        st.error(f"Failed to get semantic views: {str(e)}")
        return []

def get_semantic_dimensions(session, view_name):
    """Get dimensions for a semantic view"""
    try:
        result = session.sql(f"SHOW SEMANTIC DIMENSIONS FOR SEMANTIC VIEW {view_name}").collect()
        return [row[1] for row in result]  # Dimension names in second column
    except Exception as e:
        st.error(f"Failed to get dimensions for {view_name}: {str(e)}")
        return []

def get_semantic_metrics(session, view_name):
    """Get metrics for a semantic view"""
    try:
        result = session.sql(f"SHOW SEMANTIC METRICS FOR SEMANTIC VIEW {view_name}").collect()
        return [row[1] for row in result]  # Metric names in second column
    except Exception as e:
        st.error(f"Failed to get metrics for {view_name}: {str(e)}")
        return []

def query_semantic_view(session, view_name, dimensions=None, metrics=None, filters=None, limit=10):
    """Query semantic view using semantic SQL"""
    try:
        # Build semantic SQL query
        dim_list = ", ".join(dimensions) if dimensions else ""
        metric_list = ", ".join(metrics) if metrics else ""
        
        query_parts = []
        if dim_list:
            query_parts.append(f"DIMENSIONS ({dim_list})")
        if metric_list:
            query_parts.append(f"METRICS ({metric_list})")
        
        where_clause = f"WHERE {filters}" if filters else ""
        
        query = f"""
        SELECT * FROM SEMANTIC_VIEW(
            {view_name}
            {' '.join(query_parts)}
            {where_clause}
        )
        LIMIT {limit}
        """
        
        result = session.sql(query).collect()
        return result, query
    except Exception as e:
        st.error(f"Failed to query semantic view: {str(e)}")
        return None, None

def simulate_cortex_analyst_query(session, question, semantic_view):
    """Simulate Cortex Analyst natural language query"""
    
    # For demo purposes, we'll map common questions to semantic SQL queries
    # In a real implementation, this would use the actual Cortex Analyst REST API
    
    question_lower = question.lower()
    
    if "revenue" in question_lower or "sales" in question_lower:
        dimensions = ["PRODUCT_NAME", "CUSTOMER_NAME"]
        metrics = ["TOTAL_REVENUE", "ORDER_COUNT"]
        filters = None
        
    elif "customer" in question_lower and "top" in question_lower:
        dimensions = ["CUSTOMER_NAME"]
        metrics = ["CUSTOMER_LIFETIME_VALUE", "TOTAL_ORDERS"]
        filters = None
        
    elif "product" in question_lower and ("best" in question_lower or "top" in question_lower):
        dimensions = ["PRODUCT_NAME", "CATEGORY_NAME"]
        metrics = ["TOTAL_QUANTITY_SOLD", "ORDER_COUNT"]
        filters = None
        
    elif "high value" in question_lower or "expensive" in question_lower:
        dimensions = ["CUSTOMER_NAME", "ORDER_DATE"]
        metrics = ["TOTAL_REVENUE"]
        filters = "high_value_orders"
        
    elif "recent" in question_lower or "last 30 days" in question_lower:
        dimensions = ["PRODUCT_NAME", "ORDER_DATE"]
        metrics = ["TOTAL_REVENUE", "TOTAL_QUANTITY_SOLD"]
        filters = "recent_orders"
        
    else:
        # Default query
        dimensions = ["PRODUCT_NAME", "CUSTOMER_NAME"]
        metrics = ["TOTAL_REVENUE", "ORDER_COUNT"]
        filters = None
    
    return query_semantic_view(session, semantic_view, dimensions, metrics, filters)

def create_visualization(df, chart_type="bar"):
    """Create visualizations from query results"""
    if df.empty:
        return None
    
    # Try to identify numeric columns for metrics
    numeric_cols = df.select_dtypes(include=['number']).columns.tolist()
    text_cols = df.select_dtypes(include=['object']).columns.tolist()
    
    if not numeric_cols or not text_cols:
        return None
    
    if chart_type == "bar":
        fig = px.bar(
            df, 
            x=text_cols[0], 
            y=numeric_cols[0],
            title=f"{numeric_cols[0]} by {text_cols[0]}",
            color=numeric_cols[0] if len(numeric_cols) > 0 else None
        )
    elif chart_type == "line":
        fig = px.line(
            df,
            x=text_cols[0],
            y=numeric_cols[0],
            title=f"{numeric_cols[0]} over {text_cols[0]}"
        )
    else:  # scatter
        if len(numeric_cols) >= 2:
            fig = px.scatter(
                df,
                x=numeric_cols[0],
                y=numeric_cols[1],
                color=text_cols[0] if text_cols else None,
                title=f"{numeric_cols[1]} vs {numeric_cols[0]}"
            )
        else:
            fig = px.bar(df, x=text_cols[0], y=numeric_cols[0])
    
    fig.update_layout(
        height=400,
        showlegend=True,
        xaxis_title=text_cols[0] if text_cols else "Category",
        yaxis_title=numeric_cols[0] if numeric_cols else "Value"
    )
    
    return fig

def main():
    """Main Streamlit app"""
    
    # Header
    st.markdown('<h1 class="main-header">🤖 RDF Semantic Chat Assistant</h1>', unsafe_allow_html=True)
    st.markdown("#### Powered by Snowflake Semantic Views & Cortex Analyst")
    
    # Initialize session
    if 'session' not in st.session_state:
        st.session_state.session = initialize_session()
    
    if not st.session_state.session:
        st.stop()
    
    session = st.session_state.session
    
    # Sidebar for semantic view information
    with st.sidebar:
        st.header("🎯 Semantic Views")
        
        # Get available semantic views
        semantic_views = get_semantic_views(session)
        
        if semantic_views:
            selected_view = st.selectbox(
                "Select Semantic View:",
                semantic_views,
                index=0 if semantic_views else None
            )
            
            if selected_view:
                st.markdown(f"**Current View:** `{selected_view}`")
                
                # Show dimensions
                with st.expander("📊 Available Dimensions"):
                    dimensions = get_semantic_dimensions(session, selected_view)
                    for dim in dimensions:
                        st.write(f"• {dim}")
                
                # Show metrics
                with st.expander("📈 Available Metrics"):
                    metrics = get_semantic_metrics(session, selected_view)
                    for metric in metrics:
                        st.write(f"• {metric}")
                
                # Query builder
                st.header("🔧 Query Builder")
                
                with st.form("semantic_query"):
                    selected_dimensions = st.multiselect(
                        "Select Dimensions:",
                        dimensions,
                        default=dimensions[:2] if len(dimensions) >= 2 else dimensions
                    )
                    
                    selected_metrics = st.multiselect(
                        "Select Metrics:",
                        metrics,
                        default=metrics[:2] if len(metrics) >= 2 else metrics
                    )
                    
                    query_limit = st.slider("Limit Results:", 5, 50, 10)
                    
                    if st.form_submit_button("🔍 Run Query"):
                        if selected_dimensions or selected_metrics:
                            result, query = query_semantic_view(
                                session, 
                                selected_view, 
                                selected_dimensions, 
                                selected_metrics, 
                                limit=query_limit
                            )
                            
                            if result:
                                st.session_state.last_query_result = result
                                st.session_state.last_query = query
                                st.success("Query executed successfully!")
        else:
            st.warning("No semantic views found. Please run the setup scripts first.")
    
    # Main chat interface
    col1, col2 = st.columns([2, 1])
    
    with col1:
        st.header("💬 Natural Language Chat")
        
        # Sample questions
        st.markdown('<div class="semantic-info">', unsafe_allow_html=True)
        st.markdown("**Try asking questions like:**")
        sample_questions = [
            "What is our total revenue?",
            "Show me the top customers by value",
            "Which products are selling best?",
            "What are our high-value orders?",
            "Show me recent sales trends",
            "Which categories generate the most revenue?"
        ]
        
        for i, question in enumerate(sample_questions):
            if st.button(f"💡 {question}", key=f"sample_{i}"):
                st.session_state.current_question = question
        st.markdown('</div>', unsafe_allow_html=True)
        
        # Chat input
        user_question = st.text_input(
            "Ask a question about your data:",
            value=st.session_state.get('current_question', ''),
            placeholder="e.g., What are our top-selling products this month?"
        )
        
        if st.button("🚀 Ask Cortex Analyst") and user_question:
            if semantic_views:
                with st.spinner("🤖 Cortex Analyst is thinking..."):
                    # Simulate Cortex Analyst query
                    result, query = simulate_cortex_analyst_query(
                        session, 
                        user_question, 
                        semantic_views[0]
                    )
                    
                    if result and query:
                        # Display conversation
                        st.markdown('<div class="chat-message user-message">', unsafe_allow_html=True)
                        st.markdown(f"**You:** {user_question}")
                        st.markdown('</div>', unsafe_allow_html=True)
                        
                        st.markdown('<div class="chat-message assistant-message">', unsafe_allow_html=True)
                        st.markdown("**🤖 Cortex Analyst:** I found the data you requested!")
                        st.markdown('</div>', unsafe_allow_html=True)
                        
                        # Show query used
                        with st.expander("🔍 Generated SQL Query"):
                            st.code(query, language="sql")
                        
                        # Convert result to DataFrame
                        if result:
                            df = pd.DataFrame([row.as_dict() for row in result])
                            
                            # Display results
                            st.subheader("📊 Results")
                            st.dataframe(df, use_container_width=True)
                            
                            # Store for visualization
                            st.session_state.last_query_result = df
                            st.session_state.last_question = user_question
            else:
                st.error("No semantic views available. Please run the demo setup first.")
    
    with col2:
        st.header("📈 Visualization")
        
        if 'last_query_result' in st.session_state:
            df = st.session_state.last_query_result
            
            if isinstance(df, list):  # Convert Snowpark result to DataFrame
                df = pd.DataFrame([row.as_dict() for row in df])
            
            if not df.empty:
                chart_type = st.selectbox(
                    "Chart Type:",
                    ["bar", "line", "scatter"],
                    index=0
                )
                
                fig = create_visualization(df, chart_type)
                if fig:
                    st.plotly_chart(fig, use_container_width=True)
                
                # Summary metrics
                st.subheader("📋 Summary")
                numeric_cols = df.select_dtypes(include=['number']).columns
                
                if len(numeric_cols) > 0:
                    for col in numeric_cols[:3]:  # Show up to 3 metrics
                        col_sum = df[col].sum()
                        col_avg = df[col].mean()
                        
                        st.markdown(f"""
                        <div class="metric-card">
                            <h4>{col}</h4>
                            <p><strong>Total:</strong> {col_sum:,.2f}</p>
                            <p><strong>Average:</strong> {col_avg:,.2f}</p>
                        </div>
                        """, unsafe_allow_html=True)
            else:
                st.info("No data to visualize. Run a query first!")
        else:
            st.info("No data to visualize. Run a query first!")
    
    # Footer
    st.markdown("---")
    st.markdown(
        "**🔧 Technical Details:** This app uses Snowflake Semantic Views created from RDF schemas, "
        "enabling natural language queries through Cortex Analyst. The semantic layer provides "
        "business-friendly dimensions, metrics, and filters for intuitive data exploration."
    )

if __name__ == "__main__":
    main()