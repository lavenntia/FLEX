import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import {
  fetchChatList,
  toggleEditMode,
} from '@redux/chat_list/chat_inbox/Actions'
import { searchAllChat, resetSearchAllChat } from '@redux/chat_search/Actions'
import {
  connectingToWebSocket,
  disconnectingWebSocket,
  toggleConnectedNetwork,
} from '@redux/web_socket/Actions'
import MainView from './MainView'

const mapStateToProps = state => ({
  inboxList: state.chatInbox,
  webSocket: state.webSocket.connectedToInternet,
})

const mapDispatchToProps = dispatch => ({
  fetchChatList: bindActionCreators(fetchChatList, dispatch),
  connectToWebSocket: bindActionCreators(connectingToWebSocket, dispatch),
  disconnectWebSocket: bindActionCreators(disconnectingWebSocket, dispatch),
  searchAllChat: bindActionCreators(searchAllChat, dispatch),
  resetSearchAllChat: bindActionCreators(resetSearchAllChat, dispatch),
  toggleEditMode: bindActionCreators(toggleEditMode, dispatch),
  toggleConnectedNetwork: bindActionCreators(toggleConnectedNetwork, dispatch),
  resetAllState: () => {
    dispatch({ type: 'RESET_ALL_STATE' })
  },
})

export default connect(mapStateToProps, mapDispatchToProps)(MainView)
