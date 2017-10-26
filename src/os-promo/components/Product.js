import React from 'react'
import { View, Image, StyleSheet, Text, Platform } from 'react-native'
import unescape from 'lodash/unescape'
import { ReactTPRoutes, TKPReactAnalytics } from 'NativeModules'
import TKPTouchable from '../common/TKPTouchable'

const styles = StyleSheet.create({
  productCell: {
    borderRightWidth: 1,
    borderColor: '#e0e0e0',
    backgroundColor: '#FFF',
    width: '50%',
    borderTopWidth: 1,
  },
  productImageWrapper: {
    borderBottomWidth: 1,
    borderColor: 'rgba(255,255,255,0)',
    padding: 10,
  },
  productImage: {
    height: 185,
    borderRadius: 3,
    resizeMode: 'contain',
  },
  productName: {
    fontSize: 13,
    fontWeight: '600',
    color: 'rgba(0,0,0,.7)',
    height: 40,
    paddingHorizontal: 10,
  },
  priceContainer: {
    height: 40,
  },
  productGridNormalPrice: {
    paddingHorizontal: 10,
  },
  productGridNormalPriceText: {
    fontSize: 10,
    fontWeight: '600',
    textDecorationLine: 'line-through',
  },
  priceWrapper: {
    height: 20,
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 3,
  },
  price: {
    color: '#ff5722',
    fontSize: 13,
    fontWeight: '600',
    lineHeight: 15,
    paddingHorizontal: 10,
  },
  productGridCampaignRate: {
    backgroundColor: '#f02222',
    padding: 3,
    borderRadius: 3,
    marginLeft: 5,
    justifyContent: 'center',
    alignItems: 'center',
  },
  productGridCampaignRateText: {
    color: '#fff',
    fontSize: 10,
    textAlign: 'center',
  },
  productBadgeWrapper: {
    height: 27,
    paddingVertical: 5,
    paddingHorizontal: 10,
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
  },
  productCashback: {
    borderRadius: 3,
    marginRight: 3,
    padding: 3,
    backgroundColor: '#42b549',
  },
  cashbackText: {
    color: '#fff',
    fontSize: 10,
  },
  labelText: {
    fontSize: 10,
  },
  shopSection: {
    flex: 1,
    flexDirection: 'row',
    padding: 10,
    borderTopWidth: 1,
    borderColor: '#e0e0e0',
    justifyContent: 'center',
  },
  shopImage: {
    width: 28,
    height: 28,
    ...Platform.select({
      ios: {
        resizeMode: 'contain',
      },
      android: {
        borderWidth: 1,
        borderRadius: 3,
        borderColor: '#E0E0E0',
        overlayColor: '#FFF',
      },
    }),
  },
  shopImageWrapper: {
    width: 30,
    height: 30,
    borderRadius: 3,
    borderWidth: 1,
    borderColor: '#e0e0e0',
  },
  shopNameWrapper: {
    flex: 3 / 4,
    marginTop: 7,
    marginLeft: 10,
    marginBottom: 5,
    marginRight: 0,
  },
  badgeImageContainer: {
    width: 20,
    height: 30,
    justifyContent: 'center',
    alignItems: 'center',
  },
  badgeImage: {
    height: 20,
    width: 20,
  },
  productLabel: {
    padding: 3,
    borderColor: '#e0e0e0',
    borderWidth: 1,
    marginRight: 3,
    backgroundColor: '#fff',
    borderRadius: 3,
  },
})

const handleProdPicPress = (catLevel, catName, store, prodName, prodAppUrl) => {
  const level = catLevel + 1
  const catLocation = `Level - ${level}`
  TKPReactAnalytics.trackEvent({
    name: 'clickOSMicrosite',
    category: 'Promo - Product List',
    action: 'Click',
    label: `Product - ${catLocation} - ${catName} - ${store} - ${prodName}`,
  })
  ReactTPRoutes.navigate(prodAppUrl)
}

const handleShopPress = (catLevel, catName, store, prodName, shopAppUrl) => {
  const level = catLevel + 1
  const catLocation = `Level - ${level}`

  TKPReactAnalytics.trackEvent({
    name: 'clickOSMicrosite',
    category: 'Promo - Product List',
    action: 'Click',
    label: `Shop - ${catLocation} - ${catName} - ${store} - ${prodName}`,
  })

  ReactTPRoutes.navigate(shopAppUrl)
}

const Product = ({ product, index, category }) => (
  <View style={styles.productCell}>
    <TKPTouchable
      onPress={() =>
        handleProdPicPress(
          index,
          category.category_name,
          product.data.shop.name,
          product.data.name,
          product.data.url_app,
        )}
    >
      <View>
        <View style={styles.productImageWrapper}>
          <Image
            source={{ uri: product.data.image_url }}
            style={styles.productImage}
          />
        </View>
        <Text style={styles.productName} ellipsizeMode="tail" numberOfLines={2}>
          {unescape(product.data.name)}
        </Text>
      </View>
    </TKPTouchable>
    <View style={styles.priceContainer}>
      <View style={styles.productGridNormalPrice}>
        {product.data.discount_percentage && (
          <View style={{ height: 15 }}>
            <Text style={styles.productGridNormalPriceText}>
              {product.data.original_price}
            </Text>
          </View>
        )}
      </View>
      <View style={styles.priceWrapper}>
        <Text style={styles.price}>{product.data.price}</Text>
        {product.data.discount_percentage && (
          <View style={styles.productGridCampaignRate}>
            <Text style={styles.productGridCampaignRateText}>{`${product.data
              .discount_percentage}% OFF`}</Text>
          </View>
        )}
      </View>
    </View>
    <View style={styles.productBadgeWrapper}>
      {product.data.labels.map((l, i) => {
        let labelTitle = l.title
        if (l.title.indexOf('Cashback') > -1) {
          labelTitle = 'Cashback'
        }
        switch (labelTitle) {
          case 'PO':
          case 'Grosir':
            return (
              <View style={styles.productLabel} key={i}>
                <Text style={styles.labelText}>{l.title}</Text>
              </View>
            )
          case 'Cashback':
            return (
              <View style={styles.productCashback} key={i}>
                <Text style={styles.cashbackText}>{l.title}</Text>
              </View>
            )
          default:
            return null
        }
      })}
    </View>
    <TKPTouchable
      onPress={() =>
        handleShopPress(
          index,
          category.category_name,
          product.data.shop.name,
          product.data.name,
          product.data.url_app,
        )}
    >
      <View style={styles.shopSection}>
        <View style={styles.shopImageWrapper}>
          <Image
            source={{ uri: product.brand_logo }}
            style={styles.shopImage}
          />
        </View>
        <View style={styles.shopNameWrapper}>
          <Text
            style={{ lineHeight: 15 }}
            ellipsizeMode="tail"
            numberOfLines={1}
          >
            {unescape(product.data.shop.name)}
          </Text>
        </View>
        {product.data.badges.map(
          b =>
            b.title === 'Free Return' ? (
              <View key={product.data.id} style={styles.badgeImageContainer}>
                <Image
                  source={{ uri: b.image_url }}
                  style={styles.badgeImage}
                />
              </View>
            ) : null,
        )}
      </View>
    </TKPTouchable>
  </View>
)

export default Product
