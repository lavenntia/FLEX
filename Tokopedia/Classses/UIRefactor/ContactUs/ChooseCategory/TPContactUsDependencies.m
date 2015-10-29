//
//  TPContactUsDependencies.m
//  Tokopedia
//
//  Created by Tokopedia on 9/3/15.
//  Copyright (c) 2015 TOKOPEDIA. All rights reserved.
//

#import "TPContactUsDependencies.h"

#import "ContactUsWireframe.h"
#import "ContactUsPresenter.h"
#import "ContactUsViewController.h"

#import "ContactUsFormWireframe.h"
#import "ContactUsFormPresenter.h"
#import "ContactUsFormViewController.h"

@interface TPContactUsDependencies ()

@property (nonatomic, strong) ContactUsWireframe *contactUsWireframe;
@property (nonatomic, strong) ContactUsFormWireframe *contactUsFormWireframe;

@end

@implementation TPContactUsDependencies

- (id)init {
    self = [super init];
    if (self) {
        [self configureDependencies];
    }
    return self;
}

- (void)pushContactUsViewControllerFromNavigation:(UINavigationController *)navigation {
    [self.contactUsWireframe pushContactUsViewControllerFromNavigation:navigation];
}

- (void)configureDependencies {
    [self configForm];
    [self configList];
}

- (void)configForm {
    // Contact us form set dependencies
    ContactUsFormWireframe *formWireframe = [ContactUsFormWireframe new];
    ContactUsFormViewController *formController = [ContactUsFormViewController new];
    ContactUsFormPresenter *formPresenter = [ContactUsFormPresenter new];
    ContactUsFormInteractor *formInteractor = [ContactUsFormInteractor new];
    ContactUsFormDataCollector *formDataCollector = [ContactUsFormDataCollector new];
    formInteractor.output = formPresenter;
    formInteractor.dataCollector = formDataCollector;
    formPresenter.userInterface = formController;
    formPresenter.interactor = formInteractor;
    formPresenter.wireframe = formWireframe;
    formPresenter.dataCollector = formDataCollector;
    formController.eventHandler = formPresenter;
    formWireframe.presenter = formPresenter;
    self.contactUsFormWireframe = formWireframe;
}

- (void)configList {
    // Contact us choose category set dependencies
    ContactUsWireframe *contactUsWireframe = [ContactUsWireframe new];
    ContactUsViewController *controller = [ContactUsViewController new];
    ContactUsPresenter *presenter = [ContactUsPresenter new];
    ContactUsInteractor *interactor = [ContactUsInteractor new];
    interactor.output = presenter;
    presenter.userInterface = controller;
    presenter.interactor = interactor;
    presenter.wireframe = contactUsWireframe;
    controller.eventHandler = presenter;
    contactUsWireframe.presenter = presenter;
    contactUsWireframe.formWireframe = self.contactUsFormWireframe;
    self.contactUsWireframe = contactUsWireframe;
}

@end
