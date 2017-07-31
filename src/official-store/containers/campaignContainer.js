import React, { Component } from 'react'
import { connect } from 'react-redux'
import { fetchCampaigns, addWishlistPdp, removeWishlistPdp  } from '../actions/actions'
import CampaignList from '../components/campaignList'
import {
  NativeEventEmitter
} from 'react-native';
import { 
  EventManager 
} from 'NativeModules';

const nativeTabEmitter = new NativeEventEmitter(EventManager);

class CampaignContainer extends Component {
  componentDidMount() {
    const { dispatch } = this.props
    dispatch(fetchCampaigns())

    this.loginSubscription = nativeTabEmitter.addListener("didLogin", () => {
      dispatch(fetchCampaigns())
    });

    this.logoutSubscription = nativeTabEmitter.addListener("didLogout", () => {
      dispatch(fetchCampaigns())
    });

    this.didWishlistSubscription = nativeTabEmitter.addListener("didWishlistProduct", (productId) => {
      dispatch(addWishlistPdp(productId))
    });

    this.didRemoveWishlistSubscription = nativeTabEmitter.addListener("didRemoveWishlistProduct", (productId) => {
      dispatch(removeWishlistPdp(productId))
    });
  }

  render() {
    const campaigns = this.props.campaigns.items
    return (
      this.props.campaigns.isFetching ? null :
        <CampaignList
          campaigns={campaigns} />
    )
  }

  componentWillUnmount() {
    this.logoutSubscription.remove()
    this.loginSubscription.remove()
    this.didWishlistSubscription.remove()
    this.didRemoveWishlistSubscription.remove()
  }
}

const mapStateToProps = state => {
  const campaigns = state.campaigns
  return {
    campaigns
  }
}

export default connect(mapStateToProps)(CampaignContainer)