<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>fulbii.com </title>

    <link rel="stylesheet" href="{{url('assets/css/themify-icons.css')}}">
    <link rel="stylesheet" href="{{url('assets/css/feather.css')}}">
    <!-- Favicon icon -->
    <link rel="icon" type="image/png" sizes="16x16" href="{{url('assets/images/favicon.png')}}">
    <!-- Custom Stylesheet -->
    <link rel="stylesheet" href="{{url('assets/css/style.css')}}">
    <link rel="stylesheet" href="{{url('assets/css/emoji.css')}}">
    
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.7.1/dist/leaflet.css" />

</head>

<body class="color-theme-darkgreen mont-font">

    <div class="preloader"></div>

    
    <div class="main-wrapper" style="position: absolute;height: 100%;width: 100%;">

        <div id="map" style="position:absolute; width: 100%; height: 100%; z-index:0;"></div> 
        <!--
        <div class="col-xl-6  chat-left scroll-bar">
            <div class="card shadow-xss w-100 d-block d-flex border-0 p-4 mb-3">
                <div class="card-body d-flex align-items-center p-0">
                    <h2 class="fw-700 mb-0 mt-0 font-md text-grey-900">Hotel</h2>
                    <div class="search-form-2 ms-auto">
                        <i class="ti-search font-xss"></i>
                        <input type="text" class="form-control text-grey-500 mb-0 bg-greylight theme-dark-bg border-0" placeholder="Search here.">
                    </div>
                    <a href="#" class="btn-round-md ms-2 bg-greylight theme-dark-bg rounded-3"><i class="feather-filter font-xss text-grey-500"></i></a>
                </div>
            </div>
            
            <div class="row ps-4 pe-4">
                <div class="col-lg-6 col-md-6 col-sm-6 mb-3 pe-2 ps-2">
                    <div class="card w-100 p-0 hover-card shadow-xss border-0 rounded-3 overflow-hidden me-1">
                        <span class="font-xsssss fw-700 ps-3 pe-3 lh-32 text-uppercase rounded-3 ls-2 bg-primary-gradiant d-inline-block text-white position-absolute mt-3 ms-3 z-index-1">Featured</span>
                        <div class="card-image w-100 mb-3">
                            <a href="default-hotel-details.html" class="position-relative d-block"><img src="https://via.placeholder.com/400x300.png" alt="image" class="w-100"></a>
                        </div>
                        <div class="card-body pt-0">
                            <i class="feather-bookmark font-md text-grey-500 position-absolute right-0 me-3"></i>
                            <h4 class="fw-700 font-xss mt-0 lh-28 mb-0"><a href="default-hotel-details.html" class="text-dark text-grey-900">Montana Hotel</a></h4>
                            <h6 class="font-xsssss text-grey-500 fw-600 mt-0 mb-2"> 323 Geldenfe Ave Park, Flodia City</h6>
                            <div class="star d-block w-100 text-left mt-0">
                                <img src="{{url('assets/images/star.png')}}" alt="star" class="w15 me-1 float-left">
                                <img src="{{url('assets/images/star.png')}}" alt="star" class="w15 me-1 float-left">
                                <img src="{{url('assets/images/star.png')}}" alt="star" class="w15 me-1 float-left">
                                <img src="{{url('assets/images/star.png')}}" alt="star" class="w15 me-1 float-left">
                                <img src="{{url('assets/images/star-disable.png')}}" alt="star" class="w15 me-1 float-left me-2">
                            </div>
                            <div class="clearfix"></div>
                            <h5 class="mt-3 d-inline-block font-xssss fw-600 text-grey-500 me-2"><i class="btn-round-sm bg-greylight ti-ruler-pencil text-grey-500 me-1"></i> 200 sq</h5>
                            <h5 class="mt-3 d-inline-block font-xssss fw-600 text-grey-500 me-2"><i class="btn-round-sm bg-greylight ti-rss-alt text-grey-500 me-1"></i> WiFi</h5>
                            <h5 class="mt-3 d-inline-block font-xssss fw-600 text-grey-500"><i class="btn-round-sm bg-greylight ti-credit-card text-grey-500 me-1"></i> Card</h5>
                            <div class="clearfix"></div>
                            <span class="font-lg fw-700 mt-0 pe-3 ls-2 lh-32 d-inline-block text-success float-left"><span class="font-xsssss">$</span> 320 <span class="font-xsssss text-grey-500">/ mo</span> </span>
                            <a href="#" class="position-absolute bottom-15 mb-2 right-15"><i class="btn-round-sm bg-primary-gradiant text-white font-sm feather-chevron-right"></i></a>
                        </div>
                    </div>
                </div>

                <div class="col-lg-6 col-md-6 col-sm-6 mb-3 pe-2 ps-2">
                    <div class="card w-100 p-0 hover-card shadow-xss border-0 rounded-3 overflow-hidden me-1">
                        <span class="font-xsssss fw-700 ps-3 pe-3 lh-32 text-uppercase rounded-3 ls-2 bg-primary-gradiant d-inline-block text-white position-absolute mt-3 ms-3 z-index-1">Featured</span>
                        <div class="card-image w-100 mb-3">
                            <a href="default-hotel-details.html" class="position-relative d-block"><img src="https://via.placeholder.com/400x300.png" alt="image" class="w-100"></a>
                        </div>
                        <div class="card-body pt-0">
                            <i class="feather-bookmark font-md text-grey-500 position-absolute right-0 me-3"></i>
                            <h4 class="fw-700 font-xss mt-0 lh-28 mb-0"><a href="default-hotel-details.html" class="text-dark text-grey-900">Himalayan Wind Horse</a></h4>
                            <h6 class="font-xsssss text-grey-500 fw-600 mt-0 mb-2"> 323 Geldenfe Ave Park, Flodia City</h6>
                            <div class="star d-block w-100 text-left mt-0">
                                <img src="{{url('assets/images/star.png')}}" alt="star" class="w15 me-1 float-left">
                                <img src="{{url('assets/images/star.png')}}" alt="star" class="w15 me-1 float-left">
                                <img src="{{url('assets/images/star.png')}}" alt="star" class="w15 me-1 float-left">
                                <img src="{{url('assets/images/star.png')}}" alt="star" class="w15 me-1 float-left">
                                <img src="{{url('assets/images/star-disable.png')}}" alt="star" class="w15 me-1 float-left me-2">
                            </div>
                            <div class="clearfix"></div>
                            <h5 class="mt-3 d-inline-block font-xssss fw-600 text-grey-500 me-2"><i class="btn-round-sm bg-greylight ti-ruler-pencil text-grey-500 me-1"></i> 200 sq</h5>
                            <h5 class="mt-3 d-inline-block font-xssss fw-600 text-grey-500 me-2"><i class="btn-round-sm bg-greylight ti-rss-alt text-grey-500 me-1"></i> WiFi</h5>
                            <h5 class="mt-3 d-inline-block font-xssss fw-600 text-grey-500"><i class="btn-round-sm bg-greylight ti-credit-card text-grey-500 me-1"></i> Card</h5>
                            <div class="clearfix"></div>
                            <span class="font-lg fw-700 mt-0 pe-3 ls-2 lh-32 d-inline-block text-success float-left"><span class="font-xsssss">$</span> 450 <span class="font-xsssss text-grey-500">/ mo</span> </span>
                            <a href="#" class="position-absolute bottom-15 mb-2 right-15"><i class="btn-round-sm bg-primary-gradiant text-white font-sm feather-chevron-right"></i></a>
                        </div>
                    </div>
                </div>
                <div class="col-lg-6 col-md-6 col-sm-6 mb-3 pe-2 ps-2">
                    <div class="card w-100 p-0 hover-card shadow-xss border-0 rounded-3 overflow-hidden me-1">
                        <span class="font-xsssss fw-700 ps-3 pe-3 lh-32 text-uppercase rounded-3 ls-2 bg-primary-gradiant d-inline-block text-white position-absolute mt-3 ms-3 z-index-1">Featured</span>
                        <div class="card-image w-100 mb-3">
                            <a href="default-hotel-details.html" class="position-relative d-block"><img src="https://via.placeholder.com/400x300.png" alt="image" class="w-100"></a>
                        </div>
                        <div class="card-body pt-0">
                            <i class="feather-bookmark font-md text-grey-500 position-absolute right-0 me-3"></i>
                            <h4 class="fw-700 font-xss mt-0 lh-28 mb-0"><a href="default-hotel-details.html" class="text-dark text-grey-900">Hotel Sonar Bangla</a></h4>
                            <h6 class="font-xsssss text-grey-500 fw-600 mt-0 mb-2"> 323 Geldenfe Ave Park, Flodia City</h6>
                            <div class="star d-block w-100 text-left mt-0">
                                <img src="{{url('assets/images/star.png')}}" alt="star" class="w15 me-1 float-left">
                                <img src="{{url('assets/images/star.png')}}" alt="star" class="w15 me-1 float-left">
                                <img src="{{url('assets/images/star.png')}}" alt="star" class="w15 me-1 float-left">
                                <img src="{{url('assets/images/star.png')}}" alt="star" class="w15 me-1 float-left">
                                <img src="{{url('assets/images/star-disable.png')}}" alt="star" class="w15 me-1 float-left me-2">
                            </div>
                            <div class="clearfix"></div>
                            <h5 class="mt-3 d-inline-block font-xssss fw-600 text-grey-500 me-2"><i class="btn-round-sm bg-greylight ti-ruler-pencil text-grey-500 me-1"></i> 200 sq</h5>
                            <h5 class="mt-3 d-inline-block font-xssss fw-600 text-grey-500 me-2"><i class="btn-round-sm bg-greylight ti-rss-alt text-grey-500 me-1"></i> WiFi</h5>
                            <h5 class="mt-3 d-inline-block font-xssss fw-600 text-grey-500"><i class="btn-round-sm bg-greylight ti-credit-card text-grey-500 me-1"></i> Card</h5>
                            <div class="clearfix"></div>
                            <span class="font-lg fw-700 mt-0 pe-3 ls-2 lh-32 d-inline-block text-success float-left"><span class="font-xsssss">$</span> 50 <span class="font-xsssss text-grey-500">/ mo</span> </span>
                            <a href="#" class="position-absolute bottom-15 mb-2 right-15"><i class="btn-round-sm bg-primary-gradiant text-white font-sm feather-chevron-right"></i></a>
                        </div>
                    </div>
                </div>

                <div class="col-lg-6 col-md-6 col-sm-6 mb-3 pe-2 ps-2">
                    <div class="card w-100 p-0 hover-card shadow-xss border-0 rounded-3 overflow-hidden me-1">
                        <span class="font-xsssss fw-700 ps-3 pe-3 lh-32 text-uppercase rounded-3 ls-2 bg-primary-gradiant d-inline-block text-white position-absolute mt-3 ms-3 z-index-1">Featured</span>
                        <div class="card-image w-100 mb-3">
                            <a href="default-hotel-details.html" class="position-relative d-block"><img src="https://via.placeholder.com/400x300.png" alt="image" class="w-100"></a>
                        </div>
                        <div class="card-body pt-0">
                            <i class="feather-bookmark font-md text-grey-500 position-absolute right-0 me-3"></i>
                            <h4 class="fw-700 font-xss mt-0 lh-28 mb-0"><a href="default-hotel-details.html" class="text-dark text-grey-900">House Pool Party</a></h4>
                            <h6 class="font-xsssss text-grey-500 fw-600 mt-0 mb-2"> 323 Geldenfe Ave Park, Flodia City</h6>
                            <div class="star d-block w-100 text-left mt-0">
                                <img src="{{url('assets/images/star.png')}}" alt="star" class="w15 me-1 float-left">
                                <img src="{{url('assets/images/star.png')}}" alt="star" class="w15 me-1 float-left">
                                <img src="{{url('assets/images/star.png')}}" alt="star" class="w15 me-1 float-left">
                                <img src="{{url('assets/images/star.png')}}" alt="star" class="w15 me-1 float-left">
                                <img src="{{url('assets/images/star-disable.png')}}" alt="star" class="w15 me-1 float-left me-2">
                            </div>
                            <div class="clearfix"></div>
                            <h5 class="mt-3 d-inline-block font-xssss fw-600 text-grey-500 me-2"><i class="btn-round-sm bg-greylight ti-ruler-pencil text-grey-500 me-1"></i> 200 sq</h5>
                            <h5 class="mt-3 d-inline-block font-xssss fw-600 text-grey-500 me-2"><i class="btn-round-sm bg-greylight ti-rss-alt text-grey-500 me-1"></i> WiFi</h5>
                            <h5 class="mt-3 d-inline-block font-xssss fw-600 text-grey-500"><i class="btn-round-sm bg-greylight ti-credit-card text-grey-500 me-1"></i> Card</h5>
                            <div class="clearfix"></div>
                            <span class="font-lg fw-700 mt-0 pe-3 ls-2 lh-32 d-inline-block text-success float-left"><span class="font-xsssss">$</span> 60 <span class="font-xsssss text-grey-500">/ mo</span> </span>
                            <a href="#" class="position-absolute bottom-15 mb-2 right-15"><i class="btn-round-sm bg-primary-gradiant text-white font-sm feather-chevron-right"></i></a>
                        </div>
                    </div>
                </div>

                <div class="col-lg-6 col-md-6 col-sm-6 mb-3 pe-2 ps-2">
                    <div class="card w-100 p-0 hover-card shadow-xss border-0 rounded-3 overflow-hidden me-1">
                        <span class="font-xsssss fw-700 ps-3 pe-3 lh-32 text-uppercase rounded-3 ls-2 bg-primary-gradiant d-inline-block text-white position-absolute mt-3 ms-3 z-index-1">Featured</span>
                        <div class="card-image w-100 mb-3">
                            <a href="default-hotel-details.html" class="position-relative d-block"><img src="https://via.placeholder.com/400x300.png" alt="image" class="w-100"></a>
                        </div>
                        <div class="card-body pt-0">
                            <i class="feather-bookmark font-md text-grey-500 position-absolute right-0 me-3"></i>
                            <h4 class="fw-700 font-xss mt-0 lh-28 mb-0"><a href="default-hotel-details.html" class="text-dark text-grey-900">Silver Star Boutique</a></h4>
                            <h6 class="font-xsssss text-grey-500 fw-600 mt-0 mb-2"> 323 Geldenfe Ave Park, Flodia City</h6>
                            <div class="star d-block w-100 text-left mt-0">
                                <img src="{{url('assets/images/star.png')}}" alt="star" class="w15 me-1 float-left">
                                <img src="{{url('assets/images/star.png')}}" alt="star" class="w15 me-1 float-left">
                                <img src="{{url('assets/images/star.png')}}" alt="star" class="w15 me-1 float-left">
                                <img src="{{url('assets/images/star.png')}}" alt="star" class="w15 me-1 float-left">
                                <img src="{{url('assets/images/star-disable.png')}}" alt="star" class="w15 me-1 float-left me-2">
                            </div>
                            <div class="clearfix"></div>
                            <h5 class="mt-3 d-inline-block font-xssss fw-600 text-grey-500 me-2"><i class="btn-round-sm bg-greylight ti-ruler-pencil text-grey-500 me-1"></i> 200 sq</h5>
                            <h5 class="mt-3 d-inline-block font-xssss fw-600 text-grey-500 me-2"><i class="btn-round-sm bg-greylight ti-rss-alt text-grey-500 me-1"></i> WiFi</h5>
                            <h5 class="mt-3 d-inline-block font-xssss fw-600 text-grey-500"><i class="btn-round-sm bg-greylight ti-credit-card text-grey-500 me-1"></i> Card</h5>
                            <div class="clearfix"></div>
                            <span class="font-lg fw-700 mt-0 pe-3 ls-2 lh-32 d-inline-block text-success float-left"><span class="font-xsssss">$</span> 760 <span class="font-xsssss text-grey-500">/ mo</span> </span>
                            <a href="#" class="position-absolute bottom-15 mb-2 right-15"><i class="btn-round-sm bg-primary-gradiant text-white font-sm feather-chevron-right"></i></a>
                        </div>
                    </div>
                </div>

                <div class="col-lg-6 col-md-6 col-sm-6 mb-3 pe-2 ps-2">
                    <div class="card w-100 p-0 hover-card shadow-xss border-0 rounded-3 overflow-hidden me-1">
                        <span class="font-xsssss fw-700 ps-3 pe-3 lh-32 text-uppercase rounded-3 ls-2 bg-primary-gradiant d-inline-block text-white position-absolute mt-3 ms-3 z-index-1">Featured</span>
                        <div class="card-image w-100 mb-3">
                            <a href="default-hotel-details.html" class="position-relative d-block"><img src="https://via.placeholder.com/400x300.png" alt="image" class="w-100"></a>
                        </div>
                        <div class="card-body pt-0">
                            <i class="feather-bookmark font-md text-grey-500 position-absolute right-0 me-3"></i>
                            <h4 class="fw-700 font-xss mt-0 lh-28 mb-0"><a href="default-hotel-details.html" class="text-dark text-grey-900">Crown Retreat Hotel</a></h4>
                            <h6 class="font-xsssss text-grey-500 fw-600 mt-0 mb-2"> 323 Geldenfe Ave Park, Flodia City</h6>
                            <div class="star d-block w-100 text-left mt-0">
                                <img src="{{url('assets/images/star.png')}}" alt="star" class="w15 me-1 float-left">
                                <img src="{{url('assets/images/star.png')}}" alt="star" class="w15 me-1 float-left">
                                <img src="{{url('assets/images/star.png')}}" alt="star" class="w15 me-1 float-left">
                                <img src="{{url('assets/images/star.png')}}" alt="star" class="w15 me-1 float-left">
                                <img src="{{url('assets/images/star-disable.png')}}" alt="star" class="w15 me-1 float-left me-2">
                            </div>
                            <div class="clearfix"></div>
                            <h5 class="mt-3 d-inline-block font-xssss fw-600 text-grey-500 me-2"><i class="btn-round-sm bg-greylight ti-ruler-pencil text-grey-500 me-1"></i> 200 sq</h5>
                            <h5 class="mt-3 d-inline-block font-xssss fw-600 text-grey-500 me-2"><i class="btn-round-sm bg-greylight ti-rss-alt text-grey-500 me-1"></i> WiFi</h5>
                            <h5 class="mt-3 d-inline-block font-xssss fw-600 text-grey-500"><i class="btn-round-sm bg-greylight ti-credit-card text-grey-500 me-1"></i> Card</h5>
                            <div class="clearfix"></div>
                            <span class="font-lg fw-700 mt-0 pe-3 ls-2 lh-32 d-inline-block text-success float-left"><span class="font-xsssss">$</span> 840 <span class="font-xsssss text-grey-500">/ mo</span> </span>
                            <a href="#" class="position-absolute bottom-15 mb-2 right-15"><i class="btn-round-sm bg-primary-gradiant text-white font-sm feather-chevron-right"></i></a>
                        </div>
                    </div>
                </div>
               
            </div>
        </div>
        -->

        <div class="cancha-container">
            <div class="cancha-card" style="margin-left:10px;">
                <div class="card w-100 p-0 hover-card shadow cancha-card__ rounded-3 overflow-hidden me-1 field-div" id="div-polideportivo-cercado-1">
                    <div class="card-body pt-0 mt-3">
                        <h6 class="font-xssss fw-600 mt-0 mb-0" style="color: #5fb48b">Pichanga - Martes 23 oct.</h6>
                        <h4 class="fw-700 font-xss mt-0 mb-0 limited-width-title ">
                            <a class="text-dark text-grey-900 blanc">Polideportivo Cercado de Lima 1</a>
                        </h4>
                        <h6 class="font-xsssss text-grey-500 fw-600 mt-0 mb-2">Cercado de Lima</h6>
                        <div class="clearfix"></div>
                        <div class="clearfix"></div>
                        <!-- Ajuste de la estructura para separar la hora y duración -->
                        <span class="font-lg fw-700 mt-0 pe-3 ls-2 lh-32 d-block text-success">
                            6vs6
                            <span class="hora-duracion d-block text-grey-500">9am (2 horas)</span>
                        </span>
                        <a class="position-absolute bottom-15 mb-2 right-15">
                            <i class="btn-round-sm bg-primary-gradiant text-white font-sm feather-chevron-right"></i>
                        </a>
                    </div>
                </div>
            </div>

            <div class="cancha-card" style="margin-left:10px;">
                <div class="card w-100 p-0 hover-card shadow cancha-card__ rounded-3 overflow-hidden me-1 field-div" id="div-polideportivo-brena-1">
                    <div class="card-body pt-0 mt-3">
                        <h6 class="font-xssss fw-600 mt-0 mb-0" style="color: #5fb48b">Pichanga - Miércoles 24 oct.</h6>
                        <h4 class="fw-700 font-xss mt-0 mb-0 limited-width-title">
                            <a class="text-dark text-grey-900">Polideportivo Breña 1</a>
                        </h4>
                        <h6 class="font-xsssss text-grey-500 fw-600 mt-0 mb-2">Breña</h6>
                        <div class="clearfix"></div>
                        <div class="clearfix"></div>
                        <span class="font-lg fw-700 mt-0 pe-3 ls-2 lh-32 d-block text-success">
                            7vs7
                            <span class="hora-duracion d-block text-grey-500">10pm (1 hora)</span>
                        </span>
                        <a class="position-absolute bottom-15 mb-2 right-15">
                            <i class="btn-round-sm bg-primary-gradiant text-white font-sm feather-chevron-right"></i>
                        </a>
                    </div>
                </div>
            </div>

            <div class="cancha-card" style="margin-left:10px;">
                <div class="card w-100 p-0 hover-card shadow cancha-card__ rounded-3 overflow-hidden me-1 field-div" id="div-polideportivo-san-isidro-1">
                    <div class="card-body pt-0 mt-3">
                        <h6 class="font-xssss fw-600 mt-0 mb-0" style="color: #5fb48b">Pichanga - Viernes 26 oct.</h6>
                        <h4 class="fw-700 font-xss mt-0 mb-0 limited-width-title">
                            <a class="text-dark text-grey-900">Polideportivo San Isidro 1</a>
                        </h4>
                        <h6 class="font-xsssss text-grey-500 fw-600 mt-0 mb-2">San Isidro</h6>
                        <div class="clearfix"></div>
                        <div class="clearfix"></div>
                        <span class="font-lg fw-700 mt-0 pe-3 ls-2 lh-32 d-block text-success">
                            5vs5
                            <span class="hora-duracion d-block text-grey-500">8pm (2 horas)</span>
                        </span>
                        <a class="position-absolute bottom-15 mb-2 right-15">
                            <i class="btn-round-sm bg-primary-gradiant text-white font-sm feather-chevron-right"></i>
                        </a>
                    </div>
                </div>
            </div>

            <div class="cancha-card" style="margin-left:10px;">
                <div class="card w-100 p-0 hover-card shadow cancha-card__ rounded-3 overflow-hidden me-1 field-div" id="div-polideportivo-miraflores-1">
                    <div class="card-body pt-0 mt-3">
                        <h6 class="font-xssss fw-600 mt-0 mb-0" style="color: #5fb48b">Pichanga - Sábado 27 oct.</h6>
                        <h4 class="fw-700 font-xss mt-0 mb-0 limited-width-title">
                            <a class="text-dark text-grey-900">Polideportivo Miraflores 1</a>
                        </h4>
                        <h6 class="font-xsssss text-grey-500 fw-600 mt-0 mb-2">Miraflores</h6>
                        <div class="clearfix"></div>
                        <div class="clearfix"></div>
                        <span class="font-lg fw-700 mt-0 pe-3 ls-2 lh-32 d-block text-success">
                            6vs6
                            <span class="hora-duracion d-block text-grey-500">9pm (1 hora)</span>
                        </span>
                        <a class="position-absolute bottom-15 mb-2 right-15">
                            <i class="btn-round-sm bg-primary-gradiant text-white font-sm feather-chevron-right"></i>
                        </a>
                    </div>
                </div>
            </div>


        </div>


        <!-- navigation top-->
        <div class="nav-header bg-white shadow-xs border-0">
            <div class="nav-top">
                <a href="default.html"><img src="{{url('assets/images/favicon.png')}}"  style="height: 30px;width: 30xp;" ><span class="fredoka-font ls-3 fw-600 text-current font-xxl logo-text mb-0" style="color:black"> Fulbii</span> </a>
                <a href="#" class="mob-menu ms-auto me-2 chat-active-btn"></a>
                <a href="#" class="me-2 menu-search-icon mob-menu"></a>
                
               <!--  <button class="nav-menu me-0 ms-2"></button>-->
            </div>
            
            <div class="dropdown-menu dropdown-menu-end p-4 rounded-3 border-0 shadow-lg" aria-labelledby="dropdownMenu3">
                
                <h4 class="fw-700 font-xss mb-4">Notification</h4>
                <div class="card bg-transparent-card w-100 border-0 ps-5 mb-3">
                    <img src="https://via.placeholder.com/50x50.png" alt="user" class="w40 position-absolute left-0">
                    <h5 class="font-xsss text-grey-900 mb-1 mt-0 fw-700 d-block">Hendrix Stamp <span class="text-grey-400 font-xsssss fw-600 float-right mt-1"> 3 min</span></h5>
                    <h6 class="text-grey-500 fw-500 font-xssss lh-4">There are many variations of pass..</h6>
                </div>
                <div class="card bg-transparent-card w-100 border-0 ps-5 mb-3">
                    <img src="https://via.placeholder.com/50x50.png" alt="user" class="w40 position-absolute left-0">
                    <h5 class="font-xsss text-grey-900 mb-1 mt-0 fw-700 d-block">Goria Coast <span class="text-grey-400 font-xsssss fw-600 float-right mt-1"> 2 min</span></h5>
                    <h6 class="text-grey-500 fw-500 font-xssss lh-4">Mobile Apps UI Designer is require..</h6>
                </div>

                <div class="card bg-transparent-card w-100 border-0 ps-5 mb-3">
                    <img src="https://via.placeholder.com/50x50.png" alt="user" class="w40 position-absolute left-0">
                    <h5 class="font-xsss text-grey-900 mb-1 mt-0 fw-700 d-block">Surfiya Zakir <span class="text-grey-400 font-xsssss fw-600 float-right mt-1"> 1 min</span></h5>
                    <h6 class="text-grey-500 fw-500 font-xssss lh-4">Mobile Apps UI Designer is require..</h6>
                </div>
                <div class="card bg-transparent-card w-100 border-0 ps-5">
                    <img src="https://via.placeholder.com/50x50.png" alt="user" class="w40 position-absolute left-0">
                    <h5 class="font-xsss text-grey-900 mb-1 mt-0 fw-700 d-block">Victor Exrixon <span class="text-grey-400 font-xsssss fw-600 float-right mt-1"> 30 sec</span></h5>
                    <h6 class="text-grey-500 fw-500 font-xssss lh-4">Mobile Apps UI Designer is require..</h6>
                </div>
            </div>            

        </div>
        <!-- navigation top -->

        <!-- navigation left 
        <nav class="navigation scroll-bar">
            <div class="container ps-0 pe-0">
                <div class="nav-content">
                    
                    <div class="nav-wrap bg-white bg-transparent-card rounded-xxl shadow-xss pt-3 pb-1 mb-2 mt-2">
                        <div class="nav-caption fw-600 font-xssss text-grey-500"><span>New </span>Feeds</div>
                        <ul class="mb-1 top-content">
                            <li class="logo d-none d-xl-block d-lg-block"></li>
                            <li><a href="default.html" class="nav-content-bttn open-font" ><i class="feather-tv btn-round-md bg-blue-gradiant me-3"></i><span>Newsfeed</span></a></li>
                            <li><a href="default-badge.html" class="nav-content-bttn open-font" ><i class="feather-award btn-round-md bg-red-gradiant me-3"></i><span>Badges</span></a></li>
                            <li><a href="default-storie.html" class="nav-content-bttn open-font" ><i class="feather-globe btn-round-md bg-gold-gradiant me-3"></i><span>Explore Stories</span></a></li>
                            <li><a href="default-group.html" class="nav-content-bttn open-font" ><i class="feather-zap btn-round-md bg-mini-gradiant me-3"></i><span>Popular Groups</span></a></li>
                            <li><a href="user-page.html" class="nav-content-bttn open-font"><i class="feather-user btn-round-md bg-primary-gradiant me-3"></i><span>Author Profile </span></a></li>                        
                        </ul>
                    </div>

                    <div class="nav-wrap bg-white bg-transparent-card rounded-xxl shadow-xss pt-3 pb-1 mb-2 mt-2">
                        <div class="nav-caption fw-600 font-xssss text-grey-500"><span>More </span>Pages</div>
                        <ul class="mb-3">
                            <li><a href="default-email-box.html" class="nav-content-bttn open-font"><i class="font-xl text-current feather-inbox me-3"></i><span>Email Box</span><span class="circle-count bg-warning mt-1">584</span></a></li>
                            <li><a href="default-hotel.html" class="nav-content-bttn open-font"><i class="font-xl text-current feather-home me-3"></i><span>Near Hotel</span></a></li>
                            <li><a href="default-event.html" class="nav-content-bttn open-font"><i class="font-xl text-current feather-map-pin me-3"></i><span>Latest Event</span></a></li>
                            <li><a href="default-live-stream.html" class="nav-content-bttn open-font"><i class="font-xl text-current feather-youtube me-3"></i><span>Live Stream</span></a></li>                        
                        </ul>
                    </div>
                    <div class="nav-wrap bg-white bg-transparent-card rounded-xxl shadow-xss pt-3 pb-1">
                        <div class="nav-caption fw-600 font-xssss text-grey-500"><span></span> Account</div>
                        <ul class="mb-1">
                            <li class="logo d-none d-xl-block d-lg-block"></li>
                            <li><a href="default-settings.html" class="nav-content-bttn open-font h-auto pt-2 pb-2"><i class="font-sm feather-settings me-3 text-grey-500"></i><span>Settings</span></a></li>
                            <li><a href="default-analytics.html" class="nav-content-bttn open-font h-auto pt-2 pb-2"><i class="font-sm feather-pie-chart me-3 text-grey-500"></i><span>Analytics</span></a></li>
                            <li><a href="default-message.html" class="nav-content-bttn open-font h-auto pt-2 pb-2"><i class="font-sm feather-message-square me-3 text-grey-500"></i><span>Chat</span><span class="circle-count bg-warning mt-0">23</span></a></li>
                        </ul>
                    </div>
                </div>
            </div>
        </nav>
         navigation left -->

        
        <!-- right chat -->
        

        <div class="app-header-search">
            <form class="search-form">
                <div class="form-group searchbox mb-0 border-0 p-1">
                    <input type="text" class="form-control border-0" placeholder="Search...">
                    <i class="input-icon">
                        <ion-icon name="search-outline" role="img" class="md hydrated" aria-label="search outline"></ion-icon>
                    </i>
                    <a href="#" class="ms-1 mt-1 d-inline-block close searchbox-close">
                        <i class="ti-close font-xs"></i>
                    </a>
                </div>
            </form>
        </div>

    </div> 

    <div class="modal bottom side fade" id="Modalstries" tabindex="-1" role="dialog" style=" overflow-y: auto;">
         <div class="modal-dialog modal-dialog-centered" role="document">
            <div class="modal-content border-0 bg-transparent">
                <button type="button" class="close mt-0 position-absolute top--30 right--10" data-dismiss="modal" aria-label="Close"><i class="ti-close text-white font-xssss"></i></button>
                <div class="modal-body p-0">
                    <div class="card w-100 border-0 rounded-3 overflow-hidden bg-gradiant-bottom bg-gradiant-top">
                        <div class="owl-carousel owl-theme dot-style3 story-slider owl-dot-nav nav-none">
                            <div class="item"><img src="https://via.placeholder.com/450x800.png" alt="image"></div>
                            <div class="item"><img src="https://via.placeholder.com/450x800.png" alt="image"></div>
                            <div class="item"><img src="https://via.placeholder.com/450x800.png" alt="image"></div>
                            <div class="item"><img src="https://via.placeholder.com/450x800.png" alt="image"></div>
                            
                        </div>
                    </div>
                    <div class="form-group mt-3 mb-0 p-3 position-absolute bottom-0 z-index-1 w-100">
                        <input type="text" class="style2-input w-100 bg-transparent border-light-md p-3 pe-5 font-xssss fw-500 text-white" value="Write Comments">               
                        <span class="feather-send text-white font-md text-white position-absolute" style="bottom: 35px;right:30px;"></span>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="modal-popup-chat">
        <div class="modal-popup-wrap bg-white p-0 shadow-lg rounded-3">
            <div class="modal-popup-header w-100 border-bottom">
                <div class="card p-3 d-block border-0 d-block">
                    <figure class="avatar mb-0 float-left me-2">
                        <img src="https://via.placeholder.com/50x50.png" alt="image" class="w35 me-1">
                    </figure>
                    <h5 class="fw-700 text-primary font-xssss mt-1 mb-1">Hendrix Stamp</h5>
                    <h4 class="text-grey-500 font-xsssss mt-0 mb-0"><span class="d-inline-block bg-success btn-round-xss m-0"></span> Available</h4>
                    <a href="#" class="font-xssss position-absolute right-0 top-0 mt-3 me-4"><i class="ti-close text-grey-900 mt-2 d-inline-block"></i></a>
                </div>
            </div>
            <div class="modal-popup-body w-100 p-3 h-auto">
                <div class="message"><div class="message-content font-xssss lh-24 fw-500">Hi, how can I help you?</div></div>
                <div class="date-break font-xsssss lh-24 fw-500 text-grey-500 mt-2 mb-2">Mon 10:20am</div>
                <div class="message self text-right mt-2"><div class="message-content font-xssss lh-24 fw-500">I want those files for you. I want you to send 1 PDF and 1 image file.</div></div>
                <div class="snippet pt-3 ps-4 pb-2 pe-3 mt-2 bg-grey rounded-xl float-right" data-title=".dot-typing"><div class="stage"><div class="dot-typing"></div></div></div>
                <div class="clearfix"></div>
            </div>
            <div class="modal-popup-footer w-100 border-top">
                <div class="card p-3 d-block border-0 d-block">
                    <div class="form-group icon-right-input style1-input mb-0"><input type="text" placeholder="Start typing.." class="form-control rounded-xl bg-greylight border-0 font-xssss fw-500 ps-3"><i class="feather-send text-grey-500 font-md"></i></div>
                </div>
            </div>
        </div> 
    </div>

    <script src="https://unpkg.com/leaflet@1.7.1/dist/leaflet.js"></script>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/js/bootstrap.bundle.min.js"></script>

    <script>
    document.addEventListener('DOMContentLoaded', function() {

        var zoomLevel = window.innerWidth < 768 ? 12 : 12.5; 

        var map = L.map('map', {
                    zoomControl: false // Desactiva los controles de zoom
                }).setView([-12.0694, -77.0360], zoomLevel); // Coordenadas centrales de Lima

        var currentLayer = L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png', {
            maxZoom: 25,
            attribution: ''
        }).addTo(map);

        var userLat = null, userLng = null; // Variables para almacenar la ubicación del usuario

        // Intentar obtener la ubicación al inicio
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                function(position) {
                    userLat = position.coords.latitude;
                    userLng = position.coords.longitude;
                    console.log("Ubicación actual obtenida: ", userLat, userLng);
                },
                function(error) {
                    console.warn("Permisos de ubicación denegados: " + error.message);
                }
            );
        }

        // Datos de ejemplo de tu base de datos
        var fields = [
            {
                id: 'polideportivo-cercado-1',
                name: 'Polideportivo Cercado de Lima 1',
                x: -12.0464,
                y: -77.0428,
                description: 'Cancha sintética con buena iluminación.',
                price: 80,
                photo: 'https://www.parqueygrama.com/wp-content/uploads/2019/04/cancha-de-futbol.jpg',
                celular: '999888777'
            },
            {
                id: 'polideportivo-brena-1',
                name: 'Polideportivo Breña 1',
                x: -12.0678,
                y: -77.0546,
                description: 'Cancha de césped natural, ideal para eventos deportivos.',
                price: 100,
                photo: 'https://www.parqueygrama.com/wp-content/uploads/2019/04/cancha-de-futbol.jpg',
                celular: '999888888'
            },
            {
                id: 'polideportivo-san-isidro-1',
                name: 'Polideportivo San Isidro 1',
                x: -12.0960,
                y: -77.0381,
                description: 'Cancha con césped sintético y excelente iluminación nocturna.',
                price: 120,
                photo: 'https://www.parqueygrama.com/wp-content/uploads/2019/04/cancha-de-futbol.jpg',
                celular: '999777666'
            },
            {
                id: 'polideportivo-miraflores-1',
                name: 'Polideportivo Miraflores 1',
                x: -12.1209,
                y: -77.0290,
                description: 'Cancha con césped sintético y acceso fácil a transporte público.',
                price: 150,
                photo: 'https://www.parqueygrama.com/wp-content/uploads/2019/04/cancha-de-futbol.jpg',
                celular: '999333555'
            },
            {
                name: 'Polideportivo Magdalena 1',
                x: -12.0880,
                y: -77.0725,
                description: 'Cancha de fútbol en césped natural, ideal para eventos familiares.',
                price: 90,
                photo: 'https://www.parqueygrama.com/wp-content/uploads/2019/04/cancha-de-futbol.jpg',
                celular: '999123456'
            },
            {
                name: 'Polideportivo Barranco 1',
                x: -12.1445,
                y: -77.0199,
                description: 'Cancha techada con césped sintético y buena iluminación.',
                price: 110,
                photo: 'https://www.parqueygrama.com/wp-content/uploads/2019/04/cancha-de-futbol.jpg',
                celular: '999654321'
            },
            {
                name: 'Polideportivo Surquillo 1',
                x: -12.1105,
                y: -77.0245,
                description: 'Cancha de fútbol con césped natural y estacionamiento gratuito.',
                price: 95,
                photo: 'https://www.parqueygrama.com/wp-content/uploads/2019/04/cancha-de-futbol.jpg',
                celular: '999321123'
            },
            {
                name: 'Polideportivo Ate 1',
                x: -12.0354,
                y: -76.9286,
                description: 'Cancha moderna con césped artificial y excelente iluminación.',
                price: 85,
                photo: 'https://www.parqueygrama.com/wp-content/uploads/2019/04/cancha-de-futbol.jpg',
                celular: '999876543'
            },
            {
                name: 'Polideportivo Los Olivos 1',
                x: -11.9947,
                y: -77.0739,
                description: 'Cancha con césped sintético y buen acceso a transporte público.',
                price: 100,
                photo: 'https://www.parqueygrama.com/wp-content/uploads/2019/04/cancha-de-futbol.jpg',
                celular: '999987654'
            },
            {
                name: 'Polideportivo San Miguel 1',
                x: -12.0782,
                y: -77.0844,
                description: 'Cancha con césped natural y zona de descanso para eventos familiares.',
                price: 105,
                photo: 'https://www.parqueygrama.com/wp-content/uploads/2019/04/cancha-de-futbol.jpg',
                celular: '999111222'
            }
        ];

        var activeMarker = null;
        
        // Crear marcadores y asociarlos a los divs
        fields.forEach(function(field) {
            // Crear marcador con ícono personalizado
            var marker = L.marker([field.x, field.y], {
                icon: L.divIcon({
                    className: 'price-marker',
                    html: `<div id="marker-${field.id}" class="price-rect">S/${field.price}</div>`
                })
            }).addTo(map);

            // Guardar el id del marcador en el objeto
            field.markerElement = marker.getElement().querySelector('.price-rect');

            // Evento para hacer clic en el marcador del mapa
            marker.on('click', function() {
                resetActiveStyles();
                activeMarker = marker;

                field.markerElement.classList.add('active'); // Cambiar color del precio
                openPopup(field);
            });

            // Vincular los divs con los marcadores
            var divElement = document.getElementById(`div-${field.id}`);
            if (divElement) {
                divElement.addEventListener('click', function() {
                    resetActiveStyles();
                    activeMarker = marker;

                    divElement.classList.add('active-div'); // Cambiar color del div
                    field.markerElement.classList.add('active'); // Cambiar color del precio

                    openPopup(field);
                });
            }
        });

        function openPopup(field) {
            var popupContent = `
                <div class="popup-content">
                    <img src="${field.photo}" alt="${field.name}" class="popup-img">
                    <div class="popup-details">
                        <h4 style="margin: 2px 0px;"><b>${field.name}</b></h4>
                        <p style="margin: 4px 0px;">${field.description}</p>
                        <p style="margin: 0px;"><b>Precio:</b> S/${field.price}</p>
                        <div class="map-buttons">
                            <button id="google-maps-btn" class="map-icon-btn">
                                <img src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSc29SG1JoUgvzYrUmEBrRgXcQiNnJD3rInQw&s" alt="Google Maps" class="map-icon">
                            </button>
                            <button id="waze-btn" class="map-icon-btn">
                                <img src="https://cdn-1.webcatalog.io/catalog/waze/waze-icon-filled-256.png?v=1714776428974" alt="Waze" class="map-icon">
                            </button>
                            <button id="moovit-btn" class="map-icon-btn">
                                <img src="https://cdn-1.webcatalog.io/catalog/moovit/moovit-icon-filled-256.webp?v=1725198471542" alt="Moovit" class="map-icon">
                            </button>
                            <b style="color: green; position: absolute; bottom: 20px; right: 20px;"><< (Ruta en bus)</b>
                        </div>
                    </div>
                </div>
            `;

            var popup = L.popup({
                className: 'custom-popup',
                closeButton: true,
                closeOnClick: true
            })
            .setLatLng([field.x, field.y])
            .setContent(popupContent)
            .openOn(map);

            // Ajustar la vista del mapa para que el popup quede ligeramente más abajo del centro


            // Asignar evento click a cada botón
            document.getElementById('google-maps-btn').addEventListener('click', function() {
                var googleMapsLink = `https://www.google.com/maps/dir/?api=1&destination=${field.x},${field.y}`;
                window.open(googleMapsLink, '_blank');
            });

            document.getElementById('waze-btn').addEventListener('click', function() {
                var wazeLink = `https://ul.waze.com/ul?ll=${field.x}%2C${field.y}&navigate=yes&utm_campaign=iframe_search&utm_source=https%3A%2F%2Fdevelopers-dot-devsite-v2-prod.appspot.com&utm_medium=lm_share_location`;
                window.open(wazeLink, '_blank');
            });

            document.getElementById('moovit-btn').addEventListener('click', function() {
                var moovitLink = '';
                if (userLat && userLng) {
                    // Generar el link con ubicación actual
                    moovitLink = `https://m.moovitapp.com/lima-1102/poi/es-419?fll=${userLat}_${userLng}&tll=${field.x}_${field.y}`;
                } else {
                    // Generar el link sin ubicación actual (solo destino)
                    var formattedName = field.name.split(' ').join('%20'); // Reemplazar espacios con %20
                    moovitLink = `https://m.moovitapp.com/lima-1102/poi/${formattedName}/t/es?tll=${field.x}_${field.y}`;
                }
                window.open(moovitLink, '_blank');
            });
        }

        // Función para resetear los estilos de los marcadores y divs
        function resetActiveStyles() {
            if (activeMarker) {
                activeMarker.getElement().querySelector('.price-rect').classList.remove('active');
            }
            document.querySelectorAll('.active-div').forEach(function(div) {
                div.classList.remove('active-div');
            });
        }

    });
</script>

    <script src="{{url('assets/js/plugin.js')}}"></script>

    <script src="{{url('assets/js/lightbox.js')}}"></script>
    <script src="{{url('assets/js/scripts.js')}}"></script>

    
</body>

</html>