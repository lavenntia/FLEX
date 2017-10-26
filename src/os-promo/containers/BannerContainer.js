import React, { Component } from 'react'
import {
  View,
  Text
} from 'react-native'
import { connect } from 'react-redux'
import { fetchTopBanner } from '../actions'
import TopBanner from '../components/TopBanner'
import MainBanner from '../components/MainBanner'

class BannerContainer extends Component {
  componentDidMount() {
    const { dispatch, slug } = this.props
    dispatch(fetchTopBanner(slug))
  }

  render() {
    console.log(this.props)
    const banners = this.props.TopBanners.items
    if (banners){
       return (
          <View style={{backgroundColor: '#F8F8F8'}}>
            <TopBanner 
              navigation={this.props.navigation}
              dataTopBanners={banners}
            />
            <MainBanner dataMainBanners={banners} />
          </View>
      )
    } 

    return null
  }
}

const mapStateToProps = (state, ownProps) => {
  const TopBanners = state.banners
  const slug = ownProps.slug
  return {
    TopBanners,
    slug,
  }
}

export default connect(mapStateToProps)(BannerContainer)