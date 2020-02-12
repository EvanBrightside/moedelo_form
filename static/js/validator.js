const form = document.querySelector('.j-form-validate');
const inputs = form.querySelectorAll('input');
const orgFormSelect = form.querySelector('select#Ogr_form');
const bikInput = form.querySelector('input#Bic');

let array = [];

form.addEventListener('submit', (event) => {
  event.preventDefault();
  array = [];

  inputs.forEach((input, i) => {
    switch (input.name) {

      case 'Name':
        validateName(input);
        break;
      case 'Inn':
        validateInn(input);
        break;
      case 'Ogrn':
        if (orgFormSelect.value === "ИП") {
          validateOgrnip(input);
        } else {
          validateOgrn(input);
        }
        break;
      // case 'Okpo':
      //   validateOkpo(input);
      //   break;
      case 'Kpp':
        validateKpp(input);
        break;
      case 'Bic':
        validateBik(input);
        break;
      case 'PaymentAccount':
        validateRs(input, bikInput);
        break;
      default:
        break;

    }
  });

  if (array.length === (inputs.length-4)) {
    form.submit();
  }
})

function validateName(input) {
  const errorBlock = input.nextElementSibling
  const name = input.value

  var result = false;
  if (name === "") {
    errorBlock.innerText = "Укажите название организации или ФИО";
  } else {
    result = true;
    array.push(true);
  }
  return result;
}

function validateInn(input) {
  const errorBlock = input.nextElementSibling
  const inn = input.value

	var result = false;
	if (typeof inn === 'number') {
		inn = inn.toString();
	} else if (typeof inn !== 'string') {
		inn = '';
	}
	if (!inn.length) {
		errorBlock.innerText = 'ИНН пуст';
	} else if (/[^0-9]/.test(inn)) {
		errorBlock.innerText = 'ИНН может состоять только из цифр';
	} else if ([10, 12].indexOf(inn.length) === -1) {
		errorBlock.innerText = 'ИНН может состоять только из 10 или 12 цифр';
	} else {
		var checkDigit = function (inn, coefficients) {
			var n = 0;
			for (var i in coefficients) {
				n += coefficients[i] * inn[i];
			}
			return parseInt(n % 11 % 10);
		};
		switch (inn.length) {
			case 10:
				var n10 = checkDigit(inn, [2, 4, 10, 3, 5, 9, 4, 6, 8]);
				if (n10 === parseInt(inn[9])) {
					result = true;
          array.push(true);
				}
				break;
			case 12:
				var n11 = checkDigit(inn, [7, 2, 4, 10, 3, 5, 9, 4, 6, 8]);
				var n12 = checkDigit(inn, [3, 7, 2, 4, 10, 3, 5, 9, 4, 6, 8]);
				if ((n11 === parseInt(inn[10])) && (n12 === parseInt(inn[11]))) {
					result = true;
          array.push(true);
				}
				break;
		}
		if (!result) {
			errorBlock.innerText = 'Неправильный ИНН';
		}
	}
	return result;
}

function validateOgrn(input) {
  const errorBlock = input.nextElementSibling
  const ogrn = input.value

	var result = false;
	if (typeof ogrn === 'number') {
		ogrn = ogrn.toString();
	} else if (typeof ogrn !== 'string') {
		ogrn = '';
	}
	if (!ogrn.length) {
		errorBlock.innerText = 'ОГРН пуст';
	} else if (/[^0-9]/.test(ogrn)) {
		errorBlock.innerText = 'ОГРН может состоять только из цифр';
	} else if (ogrn.length !== 13) {
		errorBlock.innerText = 'ОГРН может состоять только из 13 цифр';
	} else {
		var n13 = parseInt((parseInt(ogrn.slice(0, -1)) % 11).toString().slice(-1));
		if (n13 === parseInt(ogrn[12])) {
			result = true;
      array.push(true);
		} else {
			errorBlock.innerText = 'Неправильный ОГРН';
		}
	}
	return result;
}

function validateOgrnip(input) {
  const errorBlock = input.nextElementSibling
  const ogrnip = input.value

	var result = false;
	if (typeof ogrnip === 'number') {
		ogrnip = ogrnip.toString();
	} else if (typeof ogrnip !== 'string') {
		ogrnip = '';
	}
	if (!ogrnip.length) {
		errorBlock.innerText = 'ОГРНИП пуст';
	} else if (/[^0-9]/.test(ogrnip)) {
		errorBlock.innerText = 'ОГРНИП может состоять только из цифр';
	} else if (ogrnip.length !== 15) {
		errorBlock.innerText = 'ОГРНИП может состоять только из 15 цифр';
	} else {
		var n15 = parseInt((parseInt(ogrnip.slice(0, -1)) % 13).toString().slice(-1));
		if (n15 === parseInt(ogrnip[14])) {
			result = true;
      array.push(true);
		} else {
			errorBlock.innerText = 'Неправильный ОГРНИП';
		}
	}
	return result;
}

function validateKpp(input) {
  const errorBlock = input.nextElementSibling
  const kpp = input.value

	var result = false;
	if (typeof kpp === 'number') {
		kpp = kpp.toString();
	} else if (typeof kpp !== 'string') {
		kpp = '';
	}
	if (!kpp.length) {
		errorBlock.innerText = 'КПП пуст';
	} else if (kpp.length !== 9) {
		errorBlock.innerText = 'КПП может состоять только из 9 знаков (цифр или заглавных букв латинского алфавита от A до Z)';
	} else if (!/^[0-9]{4}[0-9A-Z]{2}[0-9]{3}$/.test(kpp)) {
		errorBlock.innerText = 'Неправильный КПП';
	} else {
		result = true;
    array.push(true);
	}
	return result;
}

function validateBik(input) {
  const errorBlock = input.nextElementSibling
  const bik = input.value

	var result = false;
	if (typeof bik === 'number') {
		bik = bik.toString();
	} else if (typeof bik !== 'string') {
		bik = '';
	}
	if (!bik.length) {
		errorBlock.innerText = 'БИК пуст';
	} else if (/[^0-9]/.test(bik)) {
		errorBlock.innerText = 'БИК может состоять только из цифр';
	} else if (bik.length !== 9) {
		errorBlock.innerText = 'БИК может состоять только из 9 цифр';
	} else {
		result = true;
    array.push(true);
	}
	return result;
}

function validateRs(input, bikInput) {
  const errorBlock = input.nextElementSibling
  const rs = input.value

	var result = false;
	if (validateBik(bikInput)) {
    const bikValue = bikInput.value

		if (typeof rs === 'number') {
			rs = rs.toString();
		} else if (typeof rs !== 'string') {
			rs = '';
		}
		if (!rs.length) {
			errorBlock.innerText = 'Р/С пуст';
		} else if (/[^0-9]/.test(rs)) {
			errorBlock.innerText = 'Р/С может состоять только из цифр';
		} else if (rs.length !== 20) {
			errorBlock.innerText = 'Р/С может состоять только из 20 цифр';
		} else {
			var bikRs = bikValue.toString().slice(-3) + rs;
			var checksum = 0;
			var coefficients = [7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1];
			for (var i in coefficients) {
				checksum += coefficients[i] * (bikRs[i] % 10);
			}
			if (checksum % 10 === 0) {
				result = true;
        array.push(true);
			} else {
				errorBlock.innerText = 'Неправильный Р/С';
			}
		}
	}
	return result;
}

//
// function validateKs(ks, bik, error) {
// 	var result = false;
// 	if (validateBik(bik, error)) {
// 		if (typeof ks === 'number') {
// 			ks = ks.toString();
// 		} else if (typeof ks !== 'string') {
// 			ks = '';
// 		}
// 		if (!ks.length) {
// 			error.code = 1;
// 			errorBlock.innerText = 'К/С пуст';
// 		} else if (/[^0-9]/.test(ks)) {
// 			error.code = 2;
// 			errorBlock.innerText = 'К/С может состоять только из цифр';
// 		} else if (ks.length !== 20) {
// 			error.code = 3;
// 			errorBlock.innerText = 'К/С может состоять только из 20 цифр';
// 		} else {
// 			var bikKs = '0' + bik.toString().slice(4, 6) + ks;
// 			var checksum = 0;
// 			var coefficients = [7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1];
// 			for (var i in coefficients) {
// 				checksum += coefficients[i] * (bikKs[i] % 10);
// 			}
// 			if (checksum % 10 === 0) {
// 				result = true;
// 			} else {
// 				error.code = 4;
// 				errorBlock.innerText = 'Неправильное контрольное число';
// 			}
// 		}
// 	}
// 	return result;
// }
//
// function validateSnils(snils, error) {
// 	var result = false;
// 	if (typeof snils === 'number') {
// 		snils = snils.toString();
// 	} else if (typeof snils !== 'string') {
// 		snils = '';
// 	}
// 	if (!snils.length) {
// 		error.code = 1;
// 		errorBlock.innerText = 'СНИЛС пуст';
// 	} else if (/[^0-9]/.test(snils)) {
// 		error.code = 2;
// 		errorBlock.innerText = 'СНИЛС может состоять только из цифр';
// 	} else if (snils.length !== 11) {
// 		error.code = 3;
// 		errorBlock.innerText = 'СНИЛС может состоять только из 11 цифр';
// 	} else {
// 		var sum = 0;
// 		for (var i = 0; i < 9; i++) {
// 			sum += parseInt(snils[i]) * (9 - i);
// 		}
// 		var checkDigit = 0;
// 		if (sum < 100) {
// 			checkDigit = sum;
// 		} else if (sum > 101) {
// 			checkDigit = parseInt(sum % 101);
// 			if (checkDigit === 100) {
// 				checkDigit = 0;
// 			}
// 		}
// 		if (checkDigit === parseInt(snils.slice(-2))) {
// 			result = true;
// 		} else {
// 			error.code = 4;
// 			errorBlock.innerText = 'Неправильное контрольное число';
// 		}
// 	}
// 	return result;
// }

// function validateForm() {
//   if(validateName() && validateInn()) return true;
//   else return false;
// }
