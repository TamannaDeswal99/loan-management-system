# Lending System Application

A robust lending platform built with Ruby on Rails that facilitates loan management between administrators and users. The system handles loan requests, approvals, interest calculations, repayments, and loan adjustments.

## Features

### User Management
- User registration and authentication
- Role-based access control (Admin/User)
- Digital wallet for each user
- Profile management

### Loan Management
- Loan request submission
- Admin approval/rejection workflow
- Real-time interest calculation (per minute basis)
- Loan term adjustments
- Loan repayment processing
- Interest accrual tracking

### Admin Dashboard
- Overview of total loans
- Active loans monitoring
- Pending requests management
- Financial statistics
- Admin wallet balance tracking

### Wallet System
- Digital wallet for each user
- Balance management
- Transaction history
- Credit/Debit operations

## Technical Stack

### Backend
- Ruby 3.0.0
- Rails 7.0.0
- Sqlite
- Redis
- Sidekiq

### Frontend
- Bootstrap 5
- JavaScript

### Background Processing
- Sidekiq for background jobs
- Interest calculation worker
- 
