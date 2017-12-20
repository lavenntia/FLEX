import React, { Component } from 'react'
import {
  View,
  Text,
  StyleSheet,
  Image,
  ScrollView,
  TextInput,
  Button,
  Alert,
  ActivityIndicator,
  TouchableOpacity,
  KeyboardAvoidingView,
  Keyboard,
  Dimensions,
} from 'react-native'
import Dash from 'react-native-dash'
import Navigator from 'native-navigation'
import { ReactInteractionHelper } from 'NativeModules'
import SafeAreaView from 'react-native-safe-area-view'

import { getStaticMapUrl, postReview } from '../Services/api'
import PreAnimatedImage from '../../PreAnimatedImage'
import RatingStars from '../../RatingStars'
import { rupiahFormat, currencyFormat, trackEvent } from '../Lib/RideHelper'

import SourceIcon from '../Resources/ride-source.png'
import DestinationIcon from '../Resources/ride-destination.png'

const styles = StyleSheet.create({
  tripOverviewContainer: {
    borderBottomWidth: 1,
    borderColor: 'rgba(0,0,0,0.12)',
  },
  descriptionContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 14,
    paddingHorizontal: 16,
    backgroundColor: 'white',
  },
  alignRight: {
    textAlign: 'right',
  },
  subtitle: {
    fontSize: 13,
    fontWeight: '200',
    marginTop: 6,
    color: 'rgba(0,0,0,0.7)',
  },
  locationPointer: {
    width: 14,
    height: 14,
  },
  thinBorder: {
    borderBottomWidth: 1,
    borderColor: 'rgba(0,0,0,0.12)',
    height: 1,
    width: '100%',
  },
  tripContainer: {
    flexDirection: 'row',
    marginTop: 16,
    marginBottom: 24,
    paddingHorizontal: 16,
  },
  pointContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingBottom: 1.5,
    paddingTop: 2,
    marginTop: '50%',
    marginBottom: '50%',
  },
  dash: {
    width: 1,
    flex: 1,
    flexDirection: 'column',
  },
  driverPicture: {
    width: 40,
    height: 40,
    borderRadius: 20,
  },
  driverContainer: {
    flexDirection: 'row',
    paddingHorizontal: 4,
    marginLeft: 15,
    marginTop: 16,
  },
  paymentContainer: {
    backgroundColor: '#EFEFEF',
    padding: 16,
    marginTop: 16,
  },
  mutedText: {
    color: 'rgba(0,0,0,0.7)',
  },
  ratingContainer: {
    marginTop: 16,
    paddingTop: 16,
    marginBottom: 35,
    backgroundColor: '#EFEFEF',
  },
  suggestionContainer: {
    padding: 32,
    paddingBottom: 16,
    marginTop: 12,
    backgroundColor: 'white',
    alignItems: 'center',
  },
  suggestionTextInput: {
    width: '100%',
    backgroundColor: '#ffffff',
    height: 16,
    marginBottom: 4,
  },
  footerContainer: {
    backgroundColor: '#F4F4F4',
    paddingBottom: 8,
    alignItems: 'center',
    position: 'absolute',
    bottom: 0,
    width: '100%',
    zIndex: 10,
  },
  pendingFareContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  buttonContainer: {
    flex: 1,
    marginHorizontal: 50,
    marginTop: 50,
  },
  button: {
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#ff5722',
    borderRadius: 3,
    height: 50,
  },
})

class RideHistoryDetailScreen extends Component {
  constructor(props) {
    super(props)
    const { trip } = this.props
    this.state = {
      eligibleToSubmitRate: false,
      eligibleToRate: ![
        'rider_canceled',
        'no_drivers_available',
        'driver_canceled',
      ].includes(trip.status),
      rating: trip.rating.stars,
      isLoading: false,
      comment: trip.rating.comment,
      screenName: 'Ride Trip Detail Screen',
    }
  }

  componentWillMount() {
    this.keyboardDidShowSub = Keyboard.addListener(
      'keyboardDidShow',
      this.keyboardDidShow,
    )
    this.keyboardDidHideSub = Keyboard.addListener(
      'keyboardDidHide',
      this.keyboardDidHide,
    )
  }

  componentWillUnmount() {
    trackEvent('GenericUberEvent', 'click back', this.state.screenName)
    this.keyboardDidShowSub.remove()
    this.keyboardDidHideSub.remove()
  }

  keyboardDidShow = event => {
    this.scrollView.scrollToEnd({ animated: true })
  }

  keyboardDidHide = event => {
    this.scrollView.scrollToEnd({ animated: true })
  }

  handleRating = rating => {
    const { trip } = this.props
    if (trip.rating.stars > 0) {
      return
    }
    this.setState({
      rating,
      eligibleToSubmitRate: rating > 0,
    })
  }

  handleSubmit = () => {
    this.setState({
      eligibleToSubmitRate: false,
      isLoading: true,
    })
    const { trip } = this.props
    const { comment, rating } = this.state
    this.props.trip.rating.stars = rating
    this.props.trip.rating.comment = comment
    postReview({
      request_id: trip.request_id,
      stars: rating,
      comment,
    })
      .then(response => {
        if (response.status === 'OK') {
          this.setState({
            isLoading: false,
          })
          trackEvent(
            'GenericUberEvent',
            'click submit',
            `Ride Trip Detail Screen - ${rating} - ${comment}`,
          )
          Alert.alert('Your Review has been saved!')
        } else {
          this.setState({
            isLoading: false,
          })
          Alert.alert('Oops', 'Something went wrong, please try again.')
        }
      })
      .catch(error => Alert.alert('Oops', error.description))
  }

  renderStatus = status => {
    let newStatus
    let color = '#7F7F7F'
    switch (status) {
      case 'NO_DRIVERS_AVAILABLE':
        newStatus = 'DRIVER NOT AVAILABLE'
        break
      case 'RIDER_CANCELED':
        newStatus = 'YOU CANCELED'
        break
      case 'DRIVER_CANCELED':
        newStatus = 'DRIVER CANCELED'
        break
      default:
        color = '#3AB539'
        newStatus = status
    }

    return (
      <Text
        style={[
          styles.alignRight,
          styles.subtitle,
          { color, fontWeight: '500' },
        ]}
      >
        {newStatus}
      </Text>
    )
  }

  render() {
    const { trip } = this.props
    const {
      comment,
      isLoading,
      rating,
      eligibleToSubmitRate,
      eligibleToRate,
      screenName,
    } = this.state
    const { width: screenWidth } = Dimensions.get('window')

    return (
      <SafeAreaView
        style={{ flex: 1 }}
        forceInset={{ top: 'never', bottom: 'always' }}
      >
        <KeyboardAvoidingView behavior="padding" style={{ flex: 1 }}>
          <Navigator.Config title="Trip Detail" />

          <ScrollView
            ref={ref => {
              this.scrollView = ref
            }}
            style={{
              backgroundColor: '#fafafa',
            }}
          >
            <View style={{ backgroundColor: '#fafafa' }}>
              <PreAnimatedImage
                aspectRatio={2}
                source={getStaticMapUrl(trip.pickup, trip.destination)}
              />
              <View style={styles.tripOverviewContainer}>
                <View style={styles.descriptionContainer}>
                  <View>
                    <Text>{trip.create_time}</Text>
                    {eligibleToRate ? (
                      <Text style={styles.subtitle}>
                        {`${trip.vehicle.make} ${trip.vehicle.model} ${trip
                          .vehicle.license_plate}`}
                      </Text>
                    ) : null}
                  </View>
                  <View>
                    <Text style={styles.alignRight}>
                      {`${currencyFormat(
                        trip.payment.currency_code,
                      )} ${rupiahFormat(trip.payment.total_amount)}`}
                    </Text>
                    {this.renderStatus(trip.status.toUpperCase())}
                  </View>
                </View>
                <View
                  style={[
                    styles.descriptionContainer,
                    {
                      marginTop: 0,
                      justifyContent: 'center',
                      alignItems: 'center',
                    },
                  ]}
                >
                  <View>
                    <Text
                      style={[
                        styles.alignRight,
                        { fontSize: screenWidth <= 320 ? 11 : 14 },
                      ]}
                    >
                      TRIP ID: {trip.request_id}
                    </Text>
                  </View>
                </View>
                <View style={styles.tripContainer}>
                  <View
                    style={{
                      flexDirection: 'column',
                      flex: 2,
                      justifyContent: 'center',
                      alignItems: 'center',
                    }}
                  >
                    <Image style={styles.locationPointer} source={SourceIcon} />
                    <Dash
                      style={styles.dash}
                      dashColor="rgba(0,0,0,0.34)"
                      dashThickness={1}
                    />
                    <Image
                      style={styles.locationPointer}
                      source={DestinationIcon}
                    />
                  </View>
                  <View
                    style={{
                      flexDirection: 'column',
                      flex: 10,
                      justifyContent: 'center',
                    }}
                  >
                    <Text style={{ marginBottom: 8 }}>
                      {trip.pickup.address_name ? (
                        trip.pickup.address_name
                      ) : (
                        `${trip.pickup.latitude}, ${trip.pickup.longitude}`
                      )}
                    </Text>
                    <View style={styles.thinBorder} />
                    <Text style={{ marginTop: 8 }}>
                      {trip.destination.address_name ? (
                        trip.destination.address_name
                      ) : (
                        `${trip.destination.latitude}, ${trip.destination
                          .longitude}`
                      )}
                    </Text>
                  </View>
                </View>
              </View>

              {eligibleToRate ? (
                <View>
                  <View style={styles.driverContainer}>
                    <Image
                      style={styles.driverPicture}
                      source={{ url: trip.driver.picture_url }}
                    />
                    <Text style={{ alignSelf: 'center', marginLeft: 12 }}>
                      Your trip with {trip.driver.name}
                    </Text>
                  </View>

                  <View style={styles.paymentContainer}>
                    <Text
                      style={[
                        styles.mutedText,
                        { alignSelf: 'center', fontSize: 13 },
                      ]}
                    >
                      {'PAYMENT DETAILS'}
                    </Text>
                    <View
                      style={{
                        marginTop: 14,
                        flexDirection: 'row',
                        justifyContent: 'space-between',
                      }}
                    >
                      <Text style={styles.mutedText}>Total Fare</Text>
                      <Text>
                        {`${currencyFormat(
                          trip.payment.currency_code,
                        )} ${rupiahFormat(trip.payment.total_amount)}`}
                      </Text>
                    </View>
                    <View
                      style={{
                        marginTop: 12,
                        flexDirection: 'row',
                        justifyContent: 'space-between',
                      }}
                    >
                      <View style={{ flexDirection: 'row' }}>
                        <Text style={styles.mutedText}>
                          {trip.payment.payment_method === 'wallet' ? (
                            'TokoCash Charged'
                          ) : (
                            'Credit Card Charged'
                          )}
                        </Text>
                      </View>
                      <Text>
                        {`${currencyFormat(
                          trip.payment.currency_code,
                        )} ${rupiahFormat(trip.payment.paid_amount)}`}
                      </Text>
                    </View>
                    {trip &&
                    trip.cashback_top_cash_amount !== 0 &&
                    trip.cashback_top_cash_amount !== '0' && (
                      <View>
                        <View style={[styles.thinBorder, { marginTop: 12 }]} />
                        <View
                          style={{
                            marginTop: 12,
                            flexDirection: 'row',
                            justifyContent: 'space-between',
                          }}
                        >
                          <Text style={styles.mutedText}>Cashback</Text>
                          <Text>
                            {`${currencyFormat(
                              trip.payment.currency_code,
                            )} ${rupiahFormat(trip.cashback_top_cash_amount)}`}
                          </Text>
                        </View>
                      </View>
                    )}

                    {trip &&
                    trip.payment &&
                    trip.payment.pending_amount !== '' &&
                    trip.payment.pending_amount > 0 && (
                      <View>
                        <View
                          style={[
                            styles.pendingFareContainer,
                            { marginTop: 12 },
                          ]}
                        >
                          <Text style={[styles.mutedText, { color: 'red' }]}>
                            Pending Fare
                          </Text>
                          <Text style={{ color: 'red' }}>
                            {`${currencyFormat(
                              trip.payment.currency_code,
                            )} ${rupiahFormat(trip.payment.pending_amount)}`}
                          </Text>
                        </View>
                        <View style={styles.buttonContainer}>
                          <TouchableOpacity
                            style={styles.button}
                            onPress={() => {
                              Navigator.present('RidePendingFareScreen')
                            }}
                          >
                            <Text
                              style={{ color: '#FFFFFF', fontWeight: 'bold' }}
                            >
                              Pay Pending Fare
                            </Text>
                          </TouchableOpacity>
                        </View>
                      </View>
                    )}
                  </View>

                  <View style={styles.ratingContainer}>
                    <Text
                      style={[
                        styles.mutedText,
                        { alignSelf: 'center', fontSize: 13 },
                      ]}
                    >
                      {'RATE YOUR RIDE'}
                    </Text>
                    <View
                      style={{
                        alignSelf: 'center',
                        alignItems: 'center',
                        marginTop: 12,
                        flexDirection: 'row',
                      }}
                    >
                      {eligibleToRate ? (
                        <RatingStars
                          rating={rating}
                          enabled={trip.rating.stars === 0}
                          onStarPressed={this.handleRating}
                        />
                      ) : (
                        <RatingStars rating={rating} enabled={false} />
                      )}
                    </View>
                    <View style={styles.suggestionContainer}>
                      <TextInput
                        placeholder="Write suggestions..."
                        editable={eligibleToRate && trip.rating.stars === 0}
                        style={styles.suggestionTextInput}
                        onChangeText={comment => this.setState({ comment })}
                        value={comment}
                        returnKeyType={'done'}
                        blurOnSubmit
                      />
                      <View style={[styles.thinBorder, { marginBottom: 16 }]} />
                      {isLoading && (
                        <ActivityIndicator
                          animating={isLoading}
                          style={[styles.centering, { height: 37 }]}
                          size="small"
                        />
                      )}
                      {!isLoading && (
                        <Button
                          title="Submit"
                          color="#42b549"
                          disabled={!eligibleToSubmitRate}
                          onPress={this.handleSubmit}
                        />
                      )}
                    </View>
                  </View>
                </View>
              ) : null}
            </View>
          </ScrollView>
          <TouchableOpacity
            onPress={() => {
              Navigator.push('RideWebViewScreen', {
                url: trip.help_url,
                expectedCode: 'tos_confirmation_id',
              })
              trackEvent(
                'GenericUberEvent',
                'click help for trip detail',
                `${screenName} - ${trip.create_time} - ${currencyFormat(
                  trip.payment.currency_code,
                )} ${rupiahFormat(trip.payment.total_amount)} - ${trip.status}`,
              )
            }}
          >
            <View style={styles.footerContainer}>
              <View style={[styles.thinBorder, { marginBottom: 8 }]} />
              <Text style={[styles.mutedText, { fontWeight: '500' }]}>
                {'NEED HELP? '}
                <Text style={{ color: '#3AB539' }}>{'CLICK HERE'}</Text>
              </Text>
            </View>
          </TouchableOpacity>
        </KeyboardAvoidingView>
      </SafeAreaView>
    )
  }
}

export default RideHistoryDetailScreen
