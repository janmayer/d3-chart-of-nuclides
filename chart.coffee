zoomed = ->
  container.attr 'transform', 'translate(' + d3.event.translate + ')scale(' + d3.event.scale + ')'
  return

dragstarted = (d) ->
  d3.event.sourceEvent.stopPropagation()
  d3.select(this).classed 'dragging', true
  force.start()
  return

dragged = (d) ->
  d3.select(this).attr('cx', d.x = d3.event.x).attr 'cy', d.y = d3.event.y
  return

dragended = (d) ->
  d3.select(this).classed 'dragging', false
  return

zoom = d3.behavior.zoom()
  .scaleExtent([
    0.4
    25
  ]).on('zoom', zoomed)

drag = d3.behavior.drag()
  .origin((d) -> d)
  .on('dragstart', dragstarted)
  .on('drag', dragged)
  .on('dragend', dragended)

margin = 
  top: 10
  right: 10
  bottom: 10
  left: 10

width  = $(window).width()  - 2 * (margin.left + margin.right)
height = $(window).height() - 2 * (margin.top + margin.bottom)

gridSize = 20

svg = d3.select('#chart').append('svg')
  .attr('width', width + margin.left + margin.right)
  .attr('height', height + margin.top + margin.bottom)
  .attr('transform', 'translate(' + margin.left + ',' + margin.right + ')')
  .call(zoom)


container = svg.append('g')

d3.json 'nuclear_wallet_cards.json', (error, data) ->
  
  colors = colorbrewer.RdYlGn[11]
  buckets = colors.length


  colorScale = d3.scale.quantile().domain([
    d3.min(data, (d) -> d.isomeres[0].massex)
    buckets - 2
    d3.max(data, (d) -> d.isomeres[0].massex)
  ]).range(colors)

  heatMap = container.selectAll('.isotope')
    .data(data)
    .enter()
    .append('g')
    .attr('width', gridSize)
    .attr('height', gridSize)
    .attr('overflow', 'hidden')
    .attr("transform", (d) -> "translate(" + ((d.A - d.Z) * gridSize) + "," + (height - margin.bottom - d.Z * gridSize) + ")" )
  
  heatMap
    .append('rect')
    .attr('width', gridSize)
    .attr('height', gridSize)
    .attr('class', 'isotope bordered')
    #.style('fill', (d) -> colorScale d.isomeres[0].massex)
    .style('fill', (d) -> 
      if d.isomeres[0].halflife_string == "STABLE"
        return "#000000"
      else
        return colorScale Math.log(d.isomeres[0].halflife) 
     )
  heatMap
    .append('text')
    .attr("x", gridSize/2)
    .attr("y", gridSize/2)
    .attr('text-anchor', 'middle')
    .attr('alignment-baseline', 'middle')
    .attr('font-size', '5px')
    .text( (d) -> d.symbol + '-' + d.A )
    .attr('fill', (d) -> 
      if d.isomeres[0].halflife_string == "STABLE"
        return "#FFFFFF"
      else
        return "#000000"
      )
  
  return

$(window).resize ->
  if @resizeTO
    clearTimeout @resizeTO
  @resizeTO = setTimeout((->
    $(this).trigger 'resizeEnd'
    return
  ), 500)
  return
$(window).bind 'resizeEnd', ->
  svg.attr('width', $(window).width() - 2 * (margin.left + margin.right)).attr 'height', $(window).height() - 2 * (margin.top + margin.bottom)
  return
