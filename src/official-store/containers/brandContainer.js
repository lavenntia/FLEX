import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import LoadMore from '../components/LoadMore'
import {
  fetchBrands,
  slideBrands,
  addToFavourite,
  resetBrands,
  addWishlistPdp,
  removeWishlistPdp
} from '../actions/actions'
import BrandList from '../components/brandList'
import {
  NativeEventEmitter
} from 'react-native';
import { 
  EventManager 
} from 'NativeModules';
const nativeTabEmitter = new NativeEventEmitter(EventManager);

class BrandContainer extends Component {
  componentDidMount() {
    const { offset, limit } = this.props.brands.pagination
    this.props.loadMore(limit, offset)

    this.loginSubscription = nativeTabEmitter.addListener("didLogin", () => {
      this.props.resetBrands(limit, offset) 
    });

    this.logoutSubscription = nativeTabEmitter.addListener("didLogout", () => {
      this.props.resetBrands(limit, offset) 
    });

    this.didWishlistSubscription = nativeTabEmitter.addListener("didWishlistProduct", (productId) => {
      this.props.addWishlistPdp(productId)
    });

    this.didRemoveWishlistSubscription = nativeTabEmitter.addListener("didRemoveWishlistProduct", (productId) => {
      this.props.removeWishlistPdp(productId)
    });
  }

  componentWillUnmount() {
    this.logoutSubscription.remove()
    this.loginSubscription.remove()
    this.didWishlistSubscription.remove()
    this.didRemoveWishlistSubscription.remove()
  }

  render() {
    const { offset, limit } = this.props.brands.pagination
    const totalBrands = this.props.brands.totalBrands
    const totalItemsCount = this.props.brands.items.length
    const isFetching = this.props.brands.isFetching
    let canFetch = true
    if ((totalBrands != 0) && (totalBrands == totalItemsCount)) {
      canFetch = false
    }

    const bannerListProps = {
      brands: this.props.brands.items,
      gridData: this.props.brands.grid.data,
      offset,
      limit,
      canFetch,
      isFetching,
      loadMore: this.props.loadMore,
      slideMore: this.props.slideMore
    }

    return (
      <BrandList {...bannerListProps} />
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  const brands = state.brands
  return {
    brands
  }
}

const mapDispatchToProps = (dispatch, ownProps) => {
  return {
    loadMore: bindActionCreators(fetchBrands, dispatch),
    slideMore: bindActionCreators(slideBrands, dispatch),
    resetBrands: bindActionCreators(resetBrands, dispatch),
    addShopToFav: bindActionCreators(addToFavourite, dispatch),
    addWishlistPdp: bindActionCreators(addWishlistPdp, dispatch),
    removeWishlistPdp: bindActionCreators(removeWishlistPdp, dispatch)
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(BrandContainer)