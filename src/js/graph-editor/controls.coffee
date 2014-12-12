###
# graph-editor/controls.coffee
###

# Selectors
PAST_STATE_CHOOSER = '#past-state-chooser'
PAST_STATE_CHOICES = '#possible-past-states'
SELECTED_PAST_STATE = '#selected-past-state'

# Element IDs
PAST_STATE_CHOICE_HEADER = 'possible-past-state-header'


makePossiblePastStateElement = (index, state) ->
  return "<li><a id='possible-past-state#{index}'>#{state.join(', ')}</a></li>"


makeHeadingElement = (graph) ->
  labelString = (node.label for node in graph.getNodesByIndex()).join(', ')
  return "<li><a id='possible-past-state-header'><strong>#{labelString}</strong></a></li><li class='divider'></li>"


makeStateSelectionHandler = (graph, state) ->
  # AWWWWW YIS
  # MUTHA
  # F***KIN
  # CLOSURES
  return ->
    graph.setPastState(state)
    $(SELECTED_PAST_STATE).html(state.join(', '))


module.exports =

  update: (graph) ->
    # Update currently displayed past state.
    if graph.pastState
      pastStateString = graph.pastState.join(', ')
    else
      pastStateString = '—'
    $(SELECTED_PAST_STATE).html(pastStateString)
    # Remove old event handler.
    $(PAST_STATE_CHOOSER).off('mouseup')
    # Bind the new one.
    $(PAST_STATE_CHOOSER).mouseup ->
      # Clear current past state options.
      $choiceList = $(PAST_STATE_CHOICES)
      $choiceList.html('')
      # Add selection handlers to each option.
      pastStates = graph.getPossiblePastStates()
      if not pastStates
        $choiceList.append('<li><a><strong>No possible past states</strong></a></li>')
      else
        # Make the new heading element.
        $choiceList.append(makeHeadingElement(graph))
        for i in [0...pastStates.length]
          newLiElt = makePossiblePastStateElement(i, pastStates[i])
          $(newLiElt).appendTo(PAST_STATE_CHOICES).mouseup(
            makeStateSelectionHandler(graph, pastStates[i])
          )
