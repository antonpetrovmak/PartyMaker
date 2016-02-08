//
//  PAMNewViewController.m
//  PartyMaker
//
//  Created by Petrov Anton on 08.02.16.
//  Copyright © 2016 Softheme. All rights reserved.
//

#import "PAMNewViewController.h"
#import "PAMParty.h"

@interface PAMNewViewController ()

@end

@implementation PAMNewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"CREATE PARTY";
    [self.navigationItem setHidesBackButton:YES];
    [self creatingTextField];
    [self creatingScrollView];
    [self creatingTextView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Fichi
- (void)blockControllersBesides:(id) controller userInteractionEnabled:(BOOL) isBlock {
    for (UIView *view in self.view.subviews) {
        if(![view isEqual:controller]){
            view.userInteractionEnabled = isBlock;
        }
    }
}

- (NSString *)getCustomTimeWithIntervale:(int) interval {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [formatter setTimeZone:timeZone];
    [formatter setDateFormat:@"HH:mm"];
    return [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:interval * 60]];
}

#pragma mark - Creating controllers
- (void)creatingTextField {
    [self.partyNameTextField setFont:[UIFont fontWithName:@"MariadPro-Regular" size:16]];
    NSDictionary *attributedDictionary = @{ NSForegroundColorAttributeName: [UIColor colorWithRed:76/255. green:82/255. blue:92/255. alpha:1]};
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@"Your party Name"
                                                                           attributes:attributedDictionary];
    [self.partyNameTextField setAttributedPlaceholder:attributedString];
}

- (void)creatingScrollView {
    for (int i = 0; i < 6; i++) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"PartyLogo_Small_%d", i]];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(190*i, 10, 190, image.size.height)];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [imageView setImage:image];
        [self.typeEventScrollView addSubview:imageView];
    }
    
    CGRect frame = self.typeEventPageControl.frame;
    frame.size.height = 22.0;
    self.typeEventPageControl.frame = frame;
}

- (void)creatingTextView {
    self.descriptionToolbar.frame = CGRectMake(0, 0, CGRectGetMaxX(self.view.bounds), 50);
    [self.descriptionToolbar sizeToFit];
    self.partyDescription.inputAccessoryView = self.descriptionToolbar;
}

#pragma mark - Action

- (IBAction)actionMoveCursor:(UIView *) sender {
    __weak PAMNewViewController* weakSelf = self;
    [UIView animateWithDuration:0.3
                     animations:^{
                         weakSelf.cursorView.center = CGPointMake(weakSelf.cursorView.center.x, sender.center.y);
                     }];
}

- (IBAction)actionChooseButton:(UIButton *)sender {
    [self blockControllersBesides:nil userInteractionEnabled:NO];
    self.datePikerView.frame = CGRectMake(0, self.view.frame.size.height,
                                          self.datePikerView.bounds.size.width, self.datePikerView.bounds.size.height);
    __weak PAMNewViewController* weakSelf = self;
    [UIView animateWithDuration:0.3
                     animations:^{
                         CGRect rect = weakSelf.datePikerView.frame;
                         rect.origin.y -= CGRectGetMaxY(weakSelf.datePikerView.bounds);
                         weakSelf.datePikerView.frame = rect;
                     }];
    [self.view addSubview:self.datePikerView];
}

- (IBAction)actionSaveButton:(UIButton *)sender {
    [self actionMoveCursor:self.closeButton];
    __weak PAMNewViewController *weakSelf = self;
    if(!self.partyDate) {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error!"
                                                                       message:@"You should enter a party date!"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler: ^(UIAlertAction* action) {
                                                             [weakSelf actionChooseButton:sender];
                                                         }];
        [alert addAction:actionOK];
        [self presentViewController:alert animated:YES completion:nil];
    }else if(!self.partyNameTextField.text.length) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error!"
                                                                       message:@"You should enter a party name!"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler: ^(UIAlertAction* action) {
                                                             [weakSelf.partyNameTextField becomeFirstResponder];
                                                         }];
        [alert addAction:actionOK];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *documentsPathWithFile = [documentsPath stringByAppendingPathComponent:@"logs.plist"];
        NSMutableArray *arrayPartyes = [[NSMutableArray alloc] init];
        
        NSCalendar *calendar =[NSCalendar currentCalendar];
        
        NSDateComponents *components = [calendar components:NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:self.partyDate];
        NSInteger intervale = ((components.hour-2) * 60 * 60) + (components.minute * 60) + components.second;
        
        NSDate *partyDate = [self.partyDate dateByAddingTimeInterval:-intervale];
        
        PAMParty *party = [[PAMParty alloc] initWithName:self.partyNameTextField.text
                                               startDate:[partyDate dateByAddingTimeInterval:self.startSlider.value*60]
                                                 endDate:[partyDate dateByAddingTimeInterval:self.endSlider.value*60]
                                                paryType:self.typeEventPageControl.currentPage
                                             description:self.partyDescription.text];
        
        if ([fileManager fileExistsAtPath:documentsPathWithFile]) {
            NSData *oldData =[NSData dataWithContentsOfFile:documentsPathWithFile];
            arrayPartyes = [NSKeyedUnarchiver unarchiveObjectWithData: oldData];
        } else {
            NSString *logsPlistPath = [[NSBundle mainBundle] pathForResource:@"logs" ofType:@"plist"];
            [fileManager copyItemAtPath:logsPlistPath toPath:documentsPathWithFile error:&error];
        }
        [arrayPartyes addObject:party];
        NSData* newData = [NSKeyedArchiver archivedDataWithRootObject: arrayPartyes];
        [newData writeToFile:documentsPathWithFile atomically:YES];
    }
    [self actionCloseButton:sender];
}

- (IBAction)actionCloseButton:(UIButton *)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)actionCancelDatePiker:(id)sender {
    [self blockControllersBesides:nil userInteractionEnabled:YES];
    __weak PAMNewViewController* weakSelf = self;
    [UIView animateWithDuration:0.3
                     animations:^{
                         CGRect rect = weakSelf.datePikerView.frame;
                         rect.origin.y += CGRectGetMaxY(weakSelf.datePikerView.bounds);
                         weakSelf.datePikerView.frame = rect;
                     }
                     completion:^(BOOL finished) {
                         [weakSelf.datePikerView removeFromSuperview];
                     }];
}

- (IBAction)actionDoneDatePiker:(id)sender {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: @"MM.dd.yyyy"];
    [self.chooseButton setTitle: [dateFormatter stringFromDate:self.datePiker.date] forState:UIControlStateNormal];
    self.partyDate = self.datePiker.date;
    [self actionCancelDatePiker:sender];
}

- (IBAction)actionSlideChanged:(UISlider *)sender {
    //[self moveCursor:slider];
    if([sender isEqual:self.startSlider]) {
        if(self.endSlider.value - sender.value <= 0) {
            self.endSlider.value = sender.value;
            self.startTimeLabel.text = [self getCustomTimeWithIntervale:(int)sender.value];
            self.endTimeLabel.text = [self getCustomTimeWithIntervale:(int)sender.value + 30];
        }
        self.startTimeLabel.text = [self getCustomTimeWithIntervale:(int)sender.value];
    } else if([sender isEqual:self.endSlider]) {
        if(self.startSlider.value - sender.value > 0) {
            self.startSlider.value = sender.value;
            self.endTimeLabel.text = [self getCustomTimeWithIntervale:(int)sender.value];
            self.startTimeLabel.text = [self getCustomTimeWithIntervale:(int)sender.value - 30];
        }
        self.endTimeLabel.text = [self getCustomTimeWithIntervale:(int)sender.value];
    }

}

- (IBAction)actionPageChange:(UIPageControl *)sender {
    [self actionMoveCursor:self.typeEventScrollView];
    CGPoint contentOffset = CGPointMake(sender.currentPage * self.typeEventScrollView.bounds.size.width, 0);
    [self.typeEventScrollView setContentOffset:contentOffset animated:YES];
}

- (IBAction)actionCancelDescription:(UIBarButtonItem *)sender {
    [self.partyDescription resignFirstResponder];
}

- (IBAction)actionDoneDescription:(UIBarButtonItem *)sender {
    [self.partyDescription resignFirstResponder];
}

#pragma mark - UITextFieldDelegate
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [self blockControllersBesides:textField userInteractionEnabled:NO];
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self blockControllersBesides:textField userInteractionEnabled:YES];
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self actionMoveCursor:scrollView];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSInteger currentPage = scrollView.contentOffset.x/scrollView.bounds.size.width;
    [self.typeEventPageControl setCurrentPage:currentPage];
}

#pragma mark - UITextViewDelegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    [self actionMoveCursor:textView];
    __weak PAMNewViewController *weakSelf = self;
    [UIView animateWithDuration:0.3
                     animations:^{
                         CGRect viewFrame = weakSelf.view.frame;
                         viewFrame.origin.y -= 250;
                         weakSelf.view.frame = viewFrame;
                     }];
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    __weak PAMNewViewController *weakSelf = self;
    [UIView animateWithDuration:0.2
                     animations:^{
                         CGRect viewFrame = weakSelf.view.frame;
                         viewFrame.origin.y = 0;
                         weakSelf.view.frame = viewFrame;
                     }];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *string = [textView.text stringByReplacingCharactersInRange:range withString:text];
    return !(string.length > 500);
}

@end
