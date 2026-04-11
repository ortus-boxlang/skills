---
name: bx-charts
description: Use this skill to create charts and graphs in BoxLang with the bx-charts module: bx:chart, bx:chartseries, bx:chartdata, chart types (bar, line, pie, doughnut, radar, polarArea, area, horizontalbar, scatter, bubble), responsive charts, custom colors, legends, and axis configuration.
---

# bx-charts: Charts & Graphs

## Installation

```bash
install-bx-module bx-charts
# CommandBox
box install bx-charts
```

> Powered by **Chart.js** under the hood. Outputs responsive, interactive HTML5 canvas-based charts.

## Components

| Component | Purpose |
|-----------|---------|
| `bx:chart` | Outer chart wrapper — defines layout, size, titles |
| `bx:chartseries` | A data series (one series = one dataset/line/set of bars) |
| `bx:chartdata` | A single data point (label + value) inside a series |

## Chart Types

| Type | Description |
|------|-------------|
| `bar` | Vertical bar chart |
| `horizontalbar` | Horizontal bar chart |
| `line` | Line chart |
| `area` | Line chart with filled area |
| `pie` | Pie chart |
| `doughnut` | Doughnut (ring) chart |
| `radar` | Radar/spider chart |
| `polarArea` | Polar area chart |
| `scatter` | Scatter plot |
| `bubble` | Bubble chart |

---

## Basic Bar Chart

```html
<bx:chart title="Monthly Sales" chartWidth="700" chartHeight="400">
    <bx:chartseries type="bar" seriesLabel="Revenue">
        <bx:chartdata item="January"  value="12500">
        <bx:chartdata item="February" value="15200">
        <bx:chartdata item="March"    value="18900">
        <bx:chartdata item="April"    value="14300">
        <bx:chartdata item="May"      value="21000">
    </bx:chartseries>
</bx:chart>
```

## Line Chart

```html
<bx:chart title="Page Views" chartWidth="800" chartHeight="350" showLegend="true">
    <bx:chartseries type="line" seriesLabel="2024">
        <bx:chartdata item="Jan" value="4200">
        <bx:chartdata item="Feb" value="5100">
        <bx:chartdata item="Mar" value="6300">
    </bx:chartseries>
    <bx:chartseries type="line" seriesLabel="2025">
        <bx:chartdata item="Jan" value="5800">
        <bx:chartdata item="Feb" value="7200">
        <bx:chartdata item="Mar" value="8500">
    </bx:chartseries>
</bx:chart>
```

## Pie Chart

```html
<bx:chart title="Browser Share" chartWidth="500" chartHeight="500" showLegend="true">
    <bx:chartseries type="pie">
        <bx:chartdata item="Chrome"  value="65">
        <bx:chartdata item="Firefox" value="12">
        <bx:chartdata item="Safari"  value="18">
        <bx:chartdata item="Edge"    value="5">
    </bx:chartseries>
</bx:chart>
```

## Dynamic Data from Query

```javascript
var salesQuery = queryExecute(
    "SELECT month_name, total_revenue FROM monthly_sales ORDER BY month_num",
    {},
    { returntype: "array" }
)
```

```html
<bx:chart title="Sales by Month" chartWidth="900" chartHeight="400" xAxisTitle="Month" yAxisTitle="Revenue ($)">
    <bx:chartseries type="bar" seriesLabel="Revenue">
        <bx:loop array="#salesQuery#" item="row">
            <bx:chartdata item="#row.month_name#" value="#row.total_revenue#">
        </bx:loop>
    </bx:chartseries>
</bx:chart>
```

## Multi-Series Comparison Chart

```html
<bx:chart
    title="Quarterly Performance"
    chartWidth="900"
    chartHeight="400"
    showLegend="true"
    seriesPlacement="cluster"
    xAxisTitle="Quarter"
    yAxisTitle="USD"
>
    <bx:chartseries type="bar" seriesLabel="Actual">
        <bx:chartdata item="Q1" value="125000">
        <bx:chartdata item="Q2" value="148000">
        <bx:chartdata item="Q3" value="162000">
        <bx:chartdata item="Q4" value="190000">
    </bx:chartseries>
    <bx:chartseries type="bar" seriesLabel="Target">
        <bx:chartdata item="Q1" value="120000">
        <bx:chartdata item="Q2" value="145000">
        <bx:chartdata item="Q3" value="170000">
        <bx:chartdata item="Q4" value="200000">
    </bx:chartseries>
</bx:chart>
```

## Responsive Chart

```html
<bx:chart
    title="Responsive Chart"
    chartWidth="100%"
    chartHeight="400"
    responsive="true"
    showBorder="false"
    backgroundColor="transparent"
>
    <bx:chartseries type="area" seriesLabel="Users">
        <bx:chartdata item="Mon" value="320">
        <bx:chartdata item="Tue" value="410">
        <bx:chartdata item="Wed" value="380">
    </bx:chartseries>
</bx:chart>
```

## `bx:chart` Attribute Reference

| Attribute | Description | Default |
|-----------|-------------|---------|
| `title` | Chart title | — |
| `chartWidth` | Width (px or %) | `400` |
| `chartHeight` | Height (px) | `400` |
| `backgroundColor` | Chart background color | `white` |
| `showLegend` | Show legend | `false` |
| `showBorder` | Show border around the chart | `true` |
| `seriesPlacement` | `cluster` (side-by-side) or `stacked` | `cluster` |
| `xAxisTitle` | X-axis label text | — |
| `yAxisTitle` | Y-axis label text | — |
| `responsive` | Enable responsive scaling | `false` |

## `bx:chartseries` Attribute Reference

| Attribute | Description |
|-----------|-------------|
| `type` | Chart type (see table above) |
| `seriesLabel` | Legend label for this series |
| `colorList` | Comma-separated color list for data points |
| `seriesColor` | Color for the entire series |

## Common Pitfalls

- ✅ `bx:chart` must always contain at least one `bx:chartseries`
- ✅ `bx:chartseries` must always contain `bx:chartdata` children
- ❌ `scatter` and `bubble` charts use `{ x, y }` or `{ x, y, r }` values — not simple `value` integers
- ✅ Use `responsive="true"` with `chartWidth="100%"` for mobile-friendly charts
- ✅ `seriesPlacement="stacked"` makes all series stack; works with `bar`, `area`, `line`
- ❌ Pie / doughnut charts should have only ONE `bx:chartseries` — use multiple `bx:chartdata` items for segments
